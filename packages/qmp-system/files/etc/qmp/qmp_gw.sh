#!/bin/sh
QMP_PATH="/etc/qmp"
SOURCE_GW=1

if [ -z "$SOURCE_OPENWRT_FUNCTIONS" ]
then
	. /lib/functions.sh
	SOURCE_OPENWRT_FUNCTIONS=1
fi
[ -z "$SOURCE_COMMON" ] && . $QMP_PATH/qmp_common.sh
[ -z "$SOURCE_FUNCTIONS" ] && . $QMP_PATH/qmp_functions.sh

qmp_exists_gateway() {
	qmp_uci_test gateways.$1
	return $?
}

# set a gateway with given name and values
# <name> [arg1name arg1value] [arg2name arg2value] ...
qmp_set_gateway()
{
	local name="$1"
	shift

	while [ $# -ge 2 ]
	do
		qmp_uci_set_raw gateways.$name.$1="$2"
		shift
		shift
	done
	qmp_uci_commit gateways
}


qmp_gw_search_default_ipv4() {
	qmp_set_gateway inet4_offer ignore 1
	qmp_set_gateway inet4 ignore 0 type search network 0.0.0.0/0 maxPrefixLen 0 tableRule 32767/253
	qmp_gw_masq_wan 0
}

qmp_gw_search_default_ipv6() {
	qmp_set_gateway inet6_offer ignore 1
	qmp_set_gateway inet6 ignore 0 type search network ::/0 maxPrefixLen 0 tableRule 32767/253
}

qmp_gw_offer_default_ipv4() {
	qmp_set_gateway inet4 ignore 1
	qmp_set_gateway inet4_offer ignore 0 type offer network 0.0.0.0/0
	qmp_gw_masq_wan 1
}

qmp_gw_offer_default_ipv6() {
	qmp_set_gateway inet6 ignore 1
	qmp_set_gateway inet6_offer ignore 0 type offer network ::/0 maxPrefixLen 0
}

qmp_gw_disable_default_ipv4() {
	qmp_set_gateway inet4 ignore 1
	qmp_set_gateway inet_offer ignore 1
	qmp_gw_masq_wan 0
}

qmp_gw_disable_default_ipv6() {
	qmp_set_gateway inet6 ignore 1
	qmp_set_gateway inet6_offer ignore 1
}

qmp_gw_default() {
	if [ -n "$2" ]
	then
		qmp_gw_$1_default_$2
	else
		qmp_gw_$1_default_ipv4
		qmp_gw_$1_default_ipv6
	fi
}

qmp_gw_add_interfaces_to_firewall_zone() {
	local cfg=$1
	local $virtual_interfaces
	for interface in $(qmp_get_devices wan)
	do
		[ -n "$virtual_interfaces" ] && virtual_interfaces="$virtual_interfaces "
		virtual_interfaces="$virtual_interfaces$(qmp_get_virtual_iface $interface)"
	done
	qmp_uci_set_raw firewall.$cfg.network="$virtual_interfaces"
}

qmp_gw_masq_wan() {
	#First parameter is 1/0 (enable/disable masquerade). Default is 1
	[ -z "$1" ] && masq=1 || masq=$1
	j=0
	v="nothing"
	wan=""

	#Looking for a firewall zone with name wan
	while [ ! -z "$v" ]; do
		v=$(qmp_uci_get_raw firewall.@zone[$j].name)
		[ "$v" == "wan" ] && { wan=$j; break; }
		j=$(( $j +1 ))
	done

	if [ -z "$wan" ]; then
	#if not found, we are going to create it
		cfg="$(qmp_uci_add_raw_get_cfg firewall zone)"
		qmp_uci_set_cfg firewall.$cfg.input=ACCEPT
		qmp_uci_set_cfg firewall.$cfg.output=ACCEPT
		qmp_uci_set_cfg firewall.$cfg.forward=ACCEPT
		qmp_uci_set_cfg firewall.$cfg.name=wan

		#seems that the openwrt firewall masquerade is not
		#compatible with the NAT applied by qMp in firewall.user
		#so for the moment we better disable it
		#qmp_uci_set_cfg firewall.$cfg.masq=$masq

		qmp_uci_set_cfg firewall.$cfg.mtu_fix=1
		qmp_uci_commit firewall

	else
	#if found we just change parameters
		qmp_uci_set_raw firewall.@zone[$wan].input=ACCEPT
		qmp_uci_set_raw firewall.@zone[$wan].output=ACCEPT
		qmp_uci_set_raw firewall.@zone[$wan].forward=ACCEPT
		#qmp_uci_set_raw firewall.@zone[$wan].masq=$masq
		qmp_uci_set_raw firewall.@zone[$wan].mtu_fix=1
		cfg=@zone[$wan]
	fi

	qmp_gw_add_interfaces_to_firewall_zone $cfg

	uci commit firewall
}

qmp_gw_apply() {
	qmp_configure_bmx6
	bmx6 -c --configReload || /etc/init.d/bmx6 restart
	iptables -F
	iptables -F -t nat
	sh /etc/firewall.user
}

