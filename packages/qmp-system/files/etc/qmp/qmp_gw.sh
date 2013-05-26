#!/bin/sh
#    Copyright (C) 2011 Fundacio Privada per a la Xarxa Oberta, Lliure i Neutral guifi.net
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
#
# Contributors:
#	Simó Albert i Beltran
#

QMP_PATH="/etc/qmp"
SOURCE_GW=1

if [ -z "$SOURCE_OPENWRT_FUNCTIONS" ]
then
	. /lib/functions.sh
	SOURCE_OPENWRT_FUNCTIONS=1
fi
[ -z "$SOURCE_COMMON" ] && . $QMP_PATH/qmp_common.sh
[ -z "$SOURCE_FUNCTIONS" ] && . $QMP_PATH/qmp_functions.sh

qmp_exists_gateway()
{
	local config=$1
	shift
	local ignore=0
	local exists

	args_key_values="$(echo $@ | awk -v RS=' ' 'NR % 2 == 1 && $0 !~ "^(ignore|(minB|b)andwidth)$" {a+=1} END {print a}')"
	uci_key_values=$(env | grep -v -e "^CONFIG_${config}_\(TYPE\|ignore\|\(minB\|b\)andwidth\)=" | grep -c "^CONFIG_${config}_")

	if [ "$args_key_values" != "$uci_key_values" ]
	then
		return
	fi

	while [ $# -ge 2 ]
	do
		if [ "$1" = "ignore" ]
		then
			ignore="$2"
		else
			config_get exists "$config" $1
			if [ "$exists" != "$2" ]
			then
				return
			fi
		fi
		shift
		shift
	done

	uci_set qmp "$config" ignore "$ignore"
	uci_commit
	qmp_gateway_found=true
}

qmp_set_gateway()
{
	config_load qmp
	qmp_gateway_found=false
	config_foreach qmp_exists_gateway gateway $@
	if ! $qmp_gateway_found
	then
		local config
		config="$(uci add qmp gateway)"
		while [ $# -ge 2 ]
		do
			uci_set qmp "$config" "$1" "$2"
			shift
			shift
		done
		uci_commit
	fi
}

qmp_gw_search_default_ipv4() {
	qmp_set_gateway ignore 1 type offer network 0.0.0.0/0
	qmp_set_gateway ignore 0 type search network 0.0.0.0/0 maxPrefixLen 0
	qmp_gw_masq_wan 0
}

qmp_gw_search_default_ipv6() {
	qmp_set_gateway ignore 1 type offer network ::/0
	qmp_set_gateway ignore 0 type search network ::/0
}

qmp_gw_offer_default_ipv4() {
	qmp_set_gateway ignore 1 type search network 0.0.0.0/0 maxPrefixLen 0
	qmp_set_gateway ignore 0 type offer network 0.0.0.0/0
	qmp_gw_masq_wan 1
}

qmp_gw_offer_default_ipv6() {
	qmp_set_gateway ignore 1 type search network ::/0
	qmp_set_gateway ignore 0 type offer network ::/0
}

qmp_gw_disable_default_ipv4() {
	qmp_set_gateway ignore 1 type search network 0.0.0.0/0 maxPrefixLen 0
	qmp_set_gateway ignore 1 type offer network 0.0.0.0/0
	qmp_gw_masq_wan 0
}

qmp_gw_disable_default_ipv6() {
	qmp_set_gateway ignore 1 type search network ::/0
	qmp_set_gateway ignore 1 type offer network ::/0
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
		qmp_uci_set_cfg firewall.$cfg.masq=$masq
		qmp_uci_commit firewall

	else
	#if found we just change parameters
		qmp_uci_set_raw firewall.@zone[$wan].input=ACCEPT
		qmp_uci_set_raw firewall.@zone[$wan].output=ACCEPT
		qmp_uci_set_raw firewall.@zone[$wan].forward=ACCEPT
		qmp_uci_set_raw firewall.@zone[$wan].masq=$masq
		cfg=@zone[$wan]
	fi

	qmp_gw_add_interfaces_to_firewall_zone $cfg
}

qmp_gw_apply() {
	qmp_configure_bmx6
	bmx6 -c --configReload || /etc/init.d/bmx6 restart
	/etc/init.d/firewall restart
}

