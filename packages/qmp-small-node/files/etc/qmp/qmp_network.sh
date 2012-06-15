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

qmp_enable_netserver() {
	qmp_uci_set networks.netserver 1
	killall -9 netserver
	netserver -6 -p 12865
}

qmp_disable_netserver() {
	qmp_uci_set networks.netserver 0
	killall -9 netserver || true
}

# Publish or unpublish lan HNA depending on qmp configuration
qmp_publish_lan() {
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

# Usage: qmp_publish_hna_bmx6_ipv4 10.22.33.64/27 [name_id]
qmp_publish_hna_bmx6() {
	netid=$(echo $1 | cut -d / -f1)
	netmask=$(echo $1 | cut -d / -f2)
	name_id="$2"

	[ -z "$netid" -o -z "$netmask" ] && { echo "Error, IP/MASK must be specified"; return; }

	is_ipv6=$(echo $netid | grep : -c)
	is_ipv4=$(echo $netid | grep . -c)

	[ $is_ipv6 -eq $is_ipv4 ] && { echo "Error in IP format"; return; }

	# if not name_id provided, getting one from netid md5sum
	[ -z "$name_id" ] && name_id="$(echo $netid | md5sum | cut -c1-5)"

	if [ $is_ipv4 ]; then
		# Checking if netmask is in ipv4 format and converting it to ipv6
		[ $netmask -lt 33 ] && netmask=$(( 128 - (32-$netmask) ))
		hna="::ffff:$netid/$netmask"
	else
		hna="$netid/$netmask"
	fi


	uci set bmx6.$name_id=hna
	uci set bmx6.$name_id.hna="$hna"
	uci commit

	bmx6 -c --test -a $hna > /dev/null
	if [ $? -eq 0 ]; then
		bmx6 -c --configReload
	else
		echo "ERROR in bmx6, check log"
	fi
}

# Unpublish a HNA, first argument is ID
qmp_unpublish_hna_bmx6() {
	[ -z "$1" ] && return
	uci delete bmx6.$1
	uci commit
	bmx6 -c --configReload
}
