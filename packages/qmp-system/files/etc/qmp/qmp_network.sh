# Copyright (C) 2011 Fundacio Privada per a la Xarxa Oberta, Lliure i Neutral guifi.net
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#    The full GNU General Public License is included in this distribution in
#    the file called "COPYING".

##############################
# Global variable definition
##############################
QMP_PATH="/etc/qmp"
TMP="/tmp"
QMPINFO="/etc/qmp/qmpinfo"

#######################
# Importing files
######################
SOURCE_NET=1
[ -z "$SOURCE_COMMON" ] && . $QMP_PATH/qmp_common.sh

qmp_configure_prepare_network() {                                                         
	local toRemove="$(uci show network | egrep "network.(lan|wan|mesh_).*=interface" | cut -d. -f2 | cut -d= -f1)"
	echo "Removing current network configuration"
	for i in $toRemove; do
		uci del network.$i
	done
	uci commit network
}

qmp_enable_netserver() {
	qmp_uci_set networks.netserver 1
	killall -9 netserver
	netserver -6 -p 12865
}

qmp_disable_netserver() {
	qmp_uci_set networks.netserver 0
	killall -9 netserver || true
}

## DISABLED
# Publish or unpublish lan HNA depending on qmp configuration
qmp_publish_lan() {
	echo "Publish LAN is a garbage, doing nothing..."
	return

	is_publish_on=$(qmp_uci_get networks.publish_lan)
	[ -z "$is_publish_on" ] && is_publish_on=0

	if [ $is_publish_on -eq 1 ]; then
		lan_addr=$(qmp_uci_get networks.lan_address)
		lan_mask=$(qmp_uci_get networks.lan_netmask)
		lan_prefix=$(qmp_get_prefix_from_netmask $lan_mask)
		lan_netid=$(qmp_get_netid_from_network $lan_addr $lan_mask)

		echo "Publishing LAN network: $lan_netid/$lan_prefix"
		qmp_publish_hna_bmx6 $lan_netid/$lan_prefix qMp_lan
	else
		qmp_unpublish_hna_bmx6 qMp_lan
	fi
}

# Usage: qmp_publish_hna_bmx6 <NETADDR/PREFIX> [Name ID]
# Example: qmp_publish_hna_bmx6 fd00:1714:1714::/64 my_lan
qmp_publish_hna_bmx6() {
	local netid=$(echo $1 | cut -d / -f1)
	local netmask=$(echo $1 | cut -d / -f2)
	local name_id="$2"

	[ -z "$netid" -o -z "$netmask" ] && { echo "Error, IP/MASK must be specified"; return; }

	local is_ipv6=$(echo $netid | grep : -c)
	[ $is_ipv6 -lt 1 ] && { echo "Error in IPv6/Prefix format"; return; }

	if [ -z "$name_id" ]; then
		local ucfg=$(uci add bmx6 unicastHna)
		[ -z "$ucfg" ] && { echo "Cannot add unicastHna entry to UCI"; return; }
		uci set bmx6.$ucfg.unicastHna="$netid/$netmask"
	else
		uci set bmx6.$name_id=unicastHna
		uci set bmx6.$name_id.unicastHna="$netid/$netmask"
	fi	
	
	uci commit bmx6

	bmx6 -c --test -u $netid/$netmask > /dev/null
	if [ $? -eq 0 ]; then
		bmx6 -c --configReload
	else
		echo "ERROR in bmx6, check log"
	fi
}

# Unpublish a HNA, first argument is IPv6 HNA or name id
qmp_unpublish_hna_bmx6() {
	if [ $(echo $1 | grep : -c) -ne 0 ]; then
		uci show bmx6.@unicastHna[].unicastHna | while read hna
			do
			if [ "$(echo $hna | cut -d= -f2)" == "$1" ]; then
				uci del bmx6.$(echo $hna | cut -d. -f2)
				return
			fi
			done
	else
		uci delete bmx6.$1
	fi
       
	uci commit
	bmx6 -c --configReload
}

qmp_radvd_enable_dev() {
	local dev="$1"
	local cfg=""
	echo "Enabling interface $1 for radvd"

	for i in $(uci show radvd.@interface[].interface 2>/dev/null); do
		if [ "$(echo $i | cut -d= -f2)" == "$dev" ]; then
			cfg="$(echo $i | cut -d. -f2)"
			break
		fi
	done
	
	if [ -z "$cfg" ]; then 
		echo "Cannot find radvd config for $dev. Addind new one"
		cfg="$(uci add radvd interface)"
		uci set radvd.$cfg.interface=$dev
	fi
	
	uci set radvd.$cfg.ignore=0
	uci set radvd.$cfg.AdvSendAdvert=1
	uci set radvd.$cfg.AdvManagedFlag=1
	uci set radvd.$cfg.IgnoreIfMissing=1
	uci commit
	echo "Done"
}

qmp_radvd_enable_prefix() {
	local dev="$1"
	local prefix="$2"
	echo "Adding prefix $route $dev to radvd"
	[ -z "$dev" -o -z "$prefix" ] && { echo "Dev or route missing, exiting"; return; }

	# Looking for the already configured device
	local cfg=""
	for i in $(uci show radvd.@prefix[].interface 2>/dev/null); do
		if [ "$(echo $i | cut -d= -f2)" == "$dev" ]; then
			cfg="$(echo $i | cut -d. -f2)"
			break
		fi
	done

	# Checking if this prefix already exists in the device
	for p in $(uci get radvd.$cfg.prefix 2>/dev/null); do
		if [ "$p" == "$prefix" ]; then
			echo "Prefix found in $dev radvd configuration, nothing to do"
			return
		fi
	done
	
	# If the configuration is not found, creating new one"
	if [ -z "$cfg" ]; then
		cfg=$(uci add radvd prefix)
		uci set radvd.$cfg.interface=$dev
	fi

	# Configuring parameters of radvd
	uci set radvd.$cfg.ignore=0
	uci set radvd.$cfg.AdvOnLink=1
	uci add_list radvd.$cfg.prefix=$prefix
	uci commit

	echo "Done"
}

qmp_radvd_enable_route() {
	local dev="$1"
	local route="$2"
	echo "Adding route $route $dev to radvd"
	[ -z "$dev" -o -z "$route" ] && { echo "Dev or route missing, exiting"; return; }

	# Looking for the already configured device
	local cfg=""
	for i in $(uci show radvd.@route[].interface 2>/dev/null); do
		if [ "$(echo $i | cut -d= -f2)" == "$dev" ]; then
			cfg="$(echo $i | cut -d. -f2)"
			break
		fi
	done

	# Checking if this prefix already exists in the device
	for p in $(uci get radvd.$cfg.prefix 2>/dev/null); do
		if [ "$p" == "$route" ]; then
			echo "Prefix found in $dev radvd configuration, nothing to do"
			return
		fi
	done
	
	# If the configuration is not found, creating new one"
	if [ -z "$cfg" ]; then
		cfg=$(uci add radvd route)
		uci set radvd.$cfg.interface=$dev
	fi

	# Configuring parameters of radvd
	uci set radvd.$cfg.ignore=0
	uci set radvd.$cfg.AdvRouteLifetime="infinity"
	uci add_list radvd.$cfg.prefix=$route
	uci commit

	echo "Done"
}

qmp_configure_lan_v6() {
	echo "Starting ULA LAN configuration"

	local prefix="$(qmp_uci_get networks.lan_ula_prefix48)"
	[ -z "$prefix" ] && { echo "No lan ULA prefix configured, skiping LAN IPv6 ULA configuration"; return; }

	local dev="$(qmp_uci_get node.primary_device)"

	if [ -z "$dev" ]; then 
		lanid="$(cat /var/log/*.log | md5sum | awk '{print $1}' | cut -c1-4)"
	else
		lanid="$(qmp_get_mac_for_dev $dev | tr -d : | cut -c9-12)"
	fi

	if [ $(echo $prefix | grep :: -c) -eq 0 ]; then
		ulan_net="$prefix:$lanid::/64"
		ulan_ip="$prefix:$lanid::1/64"
	else
		ulan_net="$prefix:$lanid:0000:0000:0000:0000/64"
		ulan_ip="$prefix:$lanid:0000:0000:0000:0001/64"
	fi

	echo "Configuring $ulan_ip as LAN ULA address"
	qmp_uci_set_raw network.lan.ip6addr=$ulan_ip
	ifup lan
	echo "Publishing $ulan_net over the mesh network"
	qmp_publish_hna_bmx6 $ulan_net ulan

	echo "Configuring radvd"
	qmp_radvd_enable_dev lan
	qmp_radvd_enable_prefix lan $ulan_ip
	qmp_radvd_enable_route lan fc00::/7
	/etc/init.d/radvd restart
	
	echo "Done"
}

# apply the non-overlapping DHCP-range preset policy
# qmp_configure_dhcp <node_id>
qmp_configure_dhcp() {
	local community_node_id="$1"
	local start=2
	local limit=253
	local leasetime="$(qmp_uci_get non_overlapping.qmp_leasetime)"
	leasetime=${leasetime:-1h}
	
	# If DHCP non overlapping enabled, configuring it (this is the layer3 roaming)
    if [ $(qmp_uci_get non_overlapping.ignore) -eq 0 ]; then
		echo "Configuring DHCP non-overlapping (roaming mode)"
		local num_grp=256
		local uci_offset="$(qmp_uci_get non_overlapping.dhcp_offset)"
		uci_offset=${uci_offset:-2}
		local offset=0
		[ $uci_offset -lt $num_grp ] && offset=$uci_offset
		start=$(( 0x$community_node_id * $num_grp + $offset ))
		limit=$(( $num_grp - $offset ))
	fi
	
	qmp_uci_set_raw dhcp.lan="dhcp"
	qmp_uci_set_raw dhcp.lan.interface="lan"
	qmp_uci_set_raw dhcp.lan.leasetime="$leasetime"
	qmp_uci_set_raw dhcp.lan.start="$start"
    qmp_uci_set_raw dhcp.lan.limit="$limit"

	if qmp_uci_test qmp.networks.disable_lan_dhcp; then
      qmp_uci_set_raw dhcp.lan.ignore="0"
    else
      qmp_uci_set_raw dhcp.lan.ignore="1"
    fi
}
