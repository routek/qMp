/*
 * niit.c
 *
 *  Created on: 11.10.2009
 *	  Author: lynxis
 *  TODO: device Hoplimit is max device ttl ?!
 *  TODO: ipv4 route check
 */

#include <linux/etherdevice.h>
#include <linux/if_arp.h>
#include <linux/module.h>
#include <linux/version.h>
#include <net/ip6_route.h>
#include <net/xfrm.h>

#include "niit.h"

#define static

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,31)
static inline void skb_dst_drop(struct sk_buff *skb) {
	   dst_release(skb->dst);
	   skb->dst = NULL;
}
#endif

struct niit_tunnel {
	__be32 ipv6prefix_1;
	__be32 ipv6prefix_2;
	__be32 ipv6prefix_3;
	int recursion;
};

/* tunnel4_dev input ipv4
   tunnel6_dev input ipv6 */
struct net_device* tunnel4_dev;
struct net_device* tunnel6_dev;

static int niit_err(struct sk_buff *skb, u32 info) {
	return 0;
}

static int niit_xmit(struct sk_buff *skb, struct net_device *dev) {
	struct niit_tunnel *tunnel = (struct niit_tunnel *) netdev_priv(tunnel4_dev);
	struct ethhdr *ethhead;
	struct iphdr *iph4;
	struct ipv6hdr *iph6;
	struct net_device_stats *stats;
	struct rt6_info *rt6; /* Route to the other host */
	struct net_device *tdev; /* Device to other host */
	__u8 nexthdr; /* IPv6 next header */
	u32 delta; /* calc space inside skb */
	unsigned int max_headroom; /* The extra header space needed */
	struct in6_addr s6addr;
	struct in6_addr d6addr;

	/*
	 * all IPv4 (includes icmp) will be encapsulated.
	 * IPv6 ICMPs for IPv4 encapsulated data should be translated
	 *
	 */
	if (skb->protocol == htons(ETH_P_IP)) {
		stats = &tunnel4_dev->stats;
		PDEBUG("niit: skb->proto = iph4 \n");
		iph4 = ip_hdr(skb);

		s6addr.in6_u.u6_addr32[0] = tunnel->ipv6prefix_1;
		s6addr.in6_u.u6_addr32[1] = tunnel->ipv6prefix_2;
		s6addr.in6_u.u6_addr32[2] = tunnel->ipv6prefix_3;
		s6addr.in6_u.u6_addr32[3] = iph4->saddr;

		d6addr.in6_u.u6_addr32[0] = tunnel->ipv6prefix_1;
		d6addr.in6_u.u6_addr32[1] = tunnel->ipv6prefix_2;
		d6addr.in6_u.u6_addr32[2] = tunnel->ipv6prefix_3;
		d6addr.in6_u.u6_addr32[3] = iph4->daddr;

		PDEBUG("niit: ipv4: saddr: %x%x%x%x \n niit: ipv4: daddr %x%x%x%x \n",
		 s6addr.in6_u.u6_addr32[0], s6addr.in6_u.u6_addr32[1],
		 s6addr.in6_u.u6_addr32[2], s6addr.in6_u.u6_addr32[3],
		 d6addr.in6_u.u6_addr32[0], d6addr.in6_u.u6_addr32[1],
		 d6addr.in6_u.u6_addr32[2], d6addr.in6_u.u6_addr32[3]);

		if ((rt6 = rt6_lookup(dev_net(tunnel4_dev), &d6addr, &s6addr, (tunnel4_dev)->iflink, 0)) == NULL) {
			stats->tx_carrier_errors++;
			goto tx_error_icmp;
		}

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,37)
                tdev = rt6->u.dst.dev;
                dst_release(&rt6->u.dst);

#else
                tdev = rt6->dst.dev;
                dst_release(&rt6->dst);

#endif
		if (tdev == dev) {
			PDEBUG("niit: recursion detected todev = dev \n");
			stats->collisions++;
			goto tx_error;
		}
		/* old MTU check */

		/*
		 * Resize the buffer to push our ipv6 head into
		 */
		max_headroom = LL_RESERVED_SPACE(tdev) + sizeof(struct ipv6hdr);

		if (skb_headroom(skb) < max_headroom || skb_shared(skb) || (skb_cloned(skb) && !skb_clone_writable(skb, 0))) {
			struct sk_buff *new_skb = skb_realloc_headroom(skb, max_headroom);
			if (!new_skb) {
				stats->tx_dropped++;
				dev_kfree_skb(skb);
				tunnel->recursion--;
				return 0;
			}
			if (skb->sk)
				skb_set_owner_w(new_skb, skb->sk);
			dev_kfree_skb(skb);
			skb = new_skb;
			iph4 = ip_hdr(skb);
		}

		delta = skb_network_header(skb) - skb->data;

		/* make our skb space best fit */
		if (delta < sizeof(struct ipv6hdr)) {
			iph6 = (struct ipv6hdr*) skb_push(skb, sizeof(struct ipv6hdr) - delta);
			PDEBUG("niit: iph6 < 0 skb->len %x \n", skb->len);
		}
		else if (delta > sizeof(struct ipv6hdr)) {
			iph6 = (struct ipv6hdr*) skb_pull(skb, delta - sizeof(struct ipv6hdr));
			PDEBUG("niit: iph6 > 0 skb->len %x \n", skb->len);
		}
		else {
			iph6 = (struct ipv6hdr*) skb->data;
			PDEBUG("niit: iph6 = 0 skb->len %x \n", skb->len);
		}
		/* how the package should look like :
		 * skb->network_header =  iph6
		 * skb->transport_header = iph4; 
                 */
		skb->transport_header = skb->network_header; /* we say skb->transport_header = iph4; */
		skb_reset_network_header(skb); /* now -> we reset the network header to skb->data which is our ipv6 paket */
		skb_reset_mac_header(skb);
		skb->mac_header = skb->network_header - sizeof(struct ethhdr);
		skb->mac_len = sizeof(struct ethhdr);

		/* add a dummy ethhdr to use correct interface linktype */
		ethhead = eth_hdr(skb);
		memcpy(ethhead->h_dest, tunnel4_dev->dev_addr, ETH_ALEN);
		memcpy(ethhead->h_source, tunnel4_dev->dev_addr, ETH_ALEN);
		ethhead->h_proto = htons(ETH_P_IPV6);

		/* prepare to send it again */
		IPCB(skb)->flags = 0;
		skb->protocol = htons(ETH_P_IPV6);
		skb->pkt_type = PACKET_HOST;
		skb->dev = tunnel4_dev;
		skb_dst_drop(skb);

		/* install v6 header */
		memset(iph6, 0, sizeof(struct ipv6hdr));
		iph6->version = 6;
		iph6->payload_len = iph4->tot_len;
		iph6->hop_limit = iph4->ttl;
		iph6->nexthdr = IPPROTO_IPIP;
		memcpy(&(iph6->saddr), &s6addr, sizeof(struct in6_addr));
		memcpy(&(iph6->daddr), &d6addr, sizeof(struct in6_addr));

		nf_reset(skb);
		netif_rx(skb);
		tunnel->recursion--;
	}
	else if (skb->protocol == htons(ETH_P_IPV6)) {
		/* got a ipv6-package and need to translate it back to ipv4 */
		__be32 s4addr;
		__be32 d4addr;
		__u8 hoplimit;
		stats = &tunnel6_dev->stats;
		PDEBUG("niit: skb->proto = iph6 \n");

		iph6 = ipv6_hdr(skb);
		if (!iph6) {
			PDEBUG("niit: cant find iph6 \n");
			goto tx_error;
		}

		/* IPv6 to IPv4 */
		hoplimit = iph6->hop_limit;
		/* check against our prefix which all packages must have */
		if (iph6->daddr.s6_addr32[0] != tunnel->ipv6prefix_1 || iph6->daddr.s6_addr32[1] != tunnel->ipv6prefix_2
				|| iph6->daddr.s6_addr32[2] != tunnel->ipv6prefix_3) {
			PDEBUG("niit: xmit ipv6(): Dst addr haven't our previx addr: %x%x%x%x, packet dropped.\n",
					iph6->daddr.s6_addr32[0], iph6->daddr.s6_addr32[1],
					iph6->daddr.s6_addr32[2], iph6->daddr.s6_addr32[3]);
			goto tx_error;
		}

		s4addr = iph6->saddr.s6_addr32[3];
		d4addr = iph6->daddr.s6_addr32[3];
		nexthdr = iph6->nexthdr;
		/* TODO nexthdr handle */
		/*
		 while(nexthdr != IPPROTO_IPIP) {

		 }
		 */
		if(nexthdr != IPPROTO_IPIP) {
			PDEBUG("niit: cant handle hdrtype : %x.\n", nexthdr);
			goto tx_error;
		}

		iph4 = ipip_hdr(skb);

		/* TODO: fix the check for a valid route */
		/*	   {
		 struct flowi fl = { .nl_u = { .ip4_u =
		 { .daddr = d4addr,
		 .saddr = s4addr,
		 .tos = RT_TOS(iph4->tos) } },
		 .oif = tunnel_dev->iflink,
		 .proto = iph4->protocol };

		 if (ip_route_output_key(dev_net(dev), &rt, &fl)) {
		 PDEBUG("niit : ip route not found \n");
		 stats->tx_carrier_errors++;
		 goto tx_error_icmp;
		 }
		 }
		 tdev = rt->u.dst.dev;
		 if (tdev == tunnel_dev) {
		 PDEBUG("niit : tdev == tunnel_dev \n");
		 ip_rt_put(rt);
		 stats->collisions++;
		 goto tx_error;
		 }

		 if (iph4->frag_off)
		 mtu = dst_mtu(&rt->u.dst) - sizeof(struct iphdr);
		 else
		 mtu = skb_dst(skb) ? dst_mtu(skb_dst(skb)) : dev->mtu;

		 if (mtu < 68) {
		 PDEBUG("niit : mtu < 68 \n");
		 stats->collisions++;
		 ip_rt_put(rt);
		 goto tx_error;
		 }
		 if (iph4->daddr && skb_dst(skb))
		 skb_dst(skb)->ops->update_pmtu(skb_dst(skb), mtu);
		 */
		/*
		 if (skb->len > mtu) {
		 icmpv6_send(skb, ICMPV6_PKT_TOOBIG, 0, mtu, dev);
		 ip_rt_put(rt);
		 goto tx_error;
		 }
		 */

		/*
		 *  check if we can reuse our skb_buff
		 */

		if (skb_shared(skb) || (skb_cloned(skb) && !skb_clone_writable(skb, 0))) {
			struct sk_buff *new_skb = skb_realloc_headroom(skb, skb_headroom(skb));
			if (!new_skb) {
				stats->tx_dropped++;
				dev_kfree_skb(skb);
				tunnel->recursion--;
				return 0;
			}
			if (skb->sk)
				skb_set_owner_w(new_skb, skb->sk);
			dev_kfree_skb(skb);
			skb = new_skb;
			iph6 = ipv6_hdr(skb);
			iph4 = ipip_hdr(skb);
		}

		delta = skb_transport_header(skb) - skb->data;
		skb_pull(skb, delta);

		/* our paket come with ... */
		/* skb->network_header iph6; */
		/* skb->transport_header iph4; */
		skb->network_header = skb->transport_header; /* we say skb->network_header = iph4; */
		skb_set_transport_header(skb, sizeof(struct iphdr));
		skb->mac_header = skb->network_header - sizeof(struct ethhdr);
		skb->mac_len = sizeof(struct ethhdr);

		/* add a dummy ethhdr to use correct interface linktype */
		ethhead = eth_hdr(skb);
		memcpy(ethhead->h_dest, tunnel6_dev->dev_addr, ETH_ALEN);
		memcpy(ethhead->h_source, tunnel6_dev->dev_addr, ETH_ALEN);
		ethhead->h_proto = htons(ETH_P_IP);

		/* prepare to send it again */
		IPCB(skb)->flags = 0;
		skb->protocol = htons(ETH_P_IP);
		skb->pkt_type = PACKET_HOST;
		skb->dev = tunnel6_dev;
		skb_dst_drop(skb);

		/* TODO: set iph4->ttl = hoplimit and recalc the checksum ! */

		/* sending */
		nf_reset(skb);
		netif_rx(skb);
		tunnel->recursion--;
	}
	else {
		stats = &tunnel6_dev->stats;
		PDEBUG("niit: unknown direction %x \n", skb->protocol);
		goto tx_error;
		/* drop */
	}
	return 0;

  tx_error_icmp: 
	dst_link_failure(skb);
	PDEBUG("niit: tx_error_icmp\n");
  tx_error:
	PDEBUG("niit: tx_error\n");
	stats->tx_errors++;
	dev_kfree_skb(skb);
	tunnel->recursion--;
	return 0;
}

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,31)
static const struct net_device_ops niit_netdev_ops = {
		.ndo_start_xmit = niit_xmit,
};
#else
static void niit_regxmit(struct net_device *dev) {
	dev->hard_start_xmit = niit_xmit;
}
#endif

static void niit_dev_setup(struct net_device *dev) {
	ether_setup(dev);
	memset(netdev_priv(dev), 0, sizeof(struct niit_tunnel));

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,31)
	dev->netdev_ops = &niit_netdev_ops;
#endif
	dev->destructor = free_netdev;
	dev->type = ARPHRD_ETHER;
	dev->mtu = ETH_DATA_LEN - sizeof(struct ipv6hdr);
	dev->flags = IFF_NOARP;
	random_ether_addr(dev->dev_addr);
}

static void __exit niit_cleanup(void) {

	rtnl_lock();
	unregister_netdevice(tunnel4_dev);
	unregister_netdevice(tunnel6_dev);
	rtnl_unlock();

}

static int __init niit_init(void) {
	int err;
	struct niit_tunnel *tunnel;
	printk(KERN_INFO "network IPv6 over IPv4 tunneling driver\n");

	err = -ENOMEM;
	tunnel4_dev = alloc_netdev(sizeof(struct niit_tunnel), "niit4to6",
			niit_dev_setup);
	tunnel6_dev = alloc_netdev(0, "niit6to4",
			niit_dev_setup);
	if (!tunnel4_dev || !tunnel6_dev) {
		err = -ENOMEM;
		goto err_alloc_dev;
	}
	tunnel = (struct niit_tunnel *) netdev_priv(tunnel4_dev);
	
	if ((err = register_netdev(tunnel4_dev)) ||
		(err = register_netdev(tunnel6_dev)))
		goto err_reg_dev;

	tunnel4_dev->mtu = 1400;
	tunnel6_dev->mtu = 1500;

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,31)
	niit_regxmit(tunnel4_dev);
	niit_regxmit(tunnel6_dev);
#endif

	tunnel->ipv6prefix_1 = htonl(NIIT_V6PREFIX_1);
	tunnel->ipv6prefix_2 = htonl(NIIT_V6PREFIX_2);
	tunnel->ipv6prefix_3 = htonl(NIIT_V6PREFIX_3);

	return 0;

err_reg_dev:
	dev_put(tunnel4_dev);
	dev_put(tunnel6_dev);
	free_netdev(tunnel4_dev);
	free_netdev(tunnel6_dev);
err_alloc_dev:
	return err;

}

module_init( niit_init);
module_exit( niit_cleanup);
MODULE_LICENSE("GPL");
MODULE_ALIAS("niit0");
