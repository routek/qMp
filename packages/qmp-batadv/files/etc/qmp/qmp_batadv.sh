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

# Defines & Imports
QMP_PATH="/etc/qmp"
SOURCE_BATADV=1
if [ -z "$SOURCE_OPENWRT_FUNCTIONS" ]
then
	. /lib/functions.sh
	SOURCE_OPENWRT_FUNCTIONS=1
fi
[ -z "$SOURCE_COMMON" ] && . $QMP_PATH/qmp_common.sh
[ -z "$SOURCE_NETWORK" ] && . $QMP_PATH/qmp_functions.sh

# Add Interface where BATMAN-adv connect
# qmp_create_batadv_interface <mesh-device> [batX-device || bat0] [mesh-interface name || mesh_batadv]
qmp_create_batadv_interface() {
	[ -z "$1" ] && echo "ERROR: Call qmp_create_batadv_interface without mesh-device (first) parameter." 
	local meshDevice=$(qmp_get_devices $1)
	local batDevice
	[ -z "$2" ] && batDevice='bat0' || batDevice="$2"
	local meshInterface
	[ -z "$3" ] && meshInterface='mesh_batadv' || meshInterface="$3"

	meshDevice=$(echo $meshDevice | sed 's/^ *//g')
	# Hem de treure la interficie eth0

 	uci set network.$meshInterface=interface
 	uci set network.$meshInterface.ifname="$meshDevice"
 	uci set network.$meshInterface.mtu=1528
 	uci set network.$meshInterface.proto='batadv'
 	uci set network.$meshInterface.mesh=$batDevice
 	uci commit
}
		
# Add Device to Interface "lan"
# qmp_add_batadv_interface <lan-interface> [batX-device || bat0]
qmp_add_batadv_interface() {
	[ -z "$1" ] && echo "ERROR: Call qmp_add_batadv_interface without lan-interface (first) parameter."
	local lanInterface=$1
	local batDevice
	local ifnameInterface
	[ -z "$2" ] && batDevice='bat0' || batDevice=$2
	local typeInterface=$(uci get network.$lanInterface.type)

	if [ "$typeInterface" == "bridge" ]; then 
		ifnameInterface=$(qmp_add_ifname_in_bridge "$batDevice" "$lanInterface")
		uci set network.$lanInterface.ifname="$ifnameInterface"
	else 
		# Interface isn't bridge, we need convert to bridge. :-(
		qmp_bat_log "Interface isn't bridge, we need convert to bridge. :-("
	fi
	uci commit
}

# qmp_check_ifname_in_bridge <ifnames> <device_search>
qmp_add_ifname_in_bridge() {
	[ -z "$2" ] && return
	local noExist=1
	local dev=$1

	local ifnameInterface=$(uci get network.$2.ifname)

	for ifname in $ifnameInterface; do
		if [ "$dev" == "$ifname" ]; then
			noExist=
		fi
	done
	[ -z $noExist ] && echo "$ifnameInterface" || echo "$ifnameInterface $dev"
}

# Create & configuration where 
# qmp_config_batadv <batadv_interface> [batX-device || bat0]
qmp_config_batadv () {
	[ -z "$1" ] && echo "ERROR: Call qmp_config_batadv without batadv-interface (first) parameter." 
	local batInterface=$1
	local batDevice
	[ -z "$2" ] && batDevice='bat0' || batDevice=$2
	 uci -q get batman-adv || qmp_create_batadv_file $batInterface $batDevice && qmp_add_batadv_file_def $batInterface $batDevice
	 # Add specific configuration
	 uci set batman-adv.$batDevice.ap_isolation=1
	 uci commit
}

#Create a empty file
qmp_create_batadv_file() {
	cat > /etc/config/batman-adv <<EOF
config 'mesh' '$2'
	option 'interfaces' '$1'
EOF
}

qmp_add_batadv_file_def() {
	uci set batman-adv.$2='mesh'
	uci set batman-adv.$2.interfaces=$1
	uci commit
}
qmp_bat_log() {
	echo $1
}

# Main function to configure BATMAN-adv
qmp_create_batadv() {
	local meshDevice='mesh'
	local lanInterface='lan'
	local batDevice
	[ -z "$1" ] && batDevice='bat0' || batDevice="$1"
	local meshInterface
	[ -z "$2" ] && meshInterface='mesh_batadv' || meshInterface="$2"

	qmp_create_batadv_interface $meshDevice $batDevice $meshInterface
	qmp_add_batadv_interface $lanInterface $batDevice
	qmp_config_batadv $meshInterface
}
