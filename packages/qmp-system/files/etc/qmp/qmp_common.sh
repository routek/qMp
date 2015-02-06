#!/bin/sh
SOURCE_COMMON=1
#DEBUG="/tmp/qmp_common.debug"

#######################
# UCI related commands
#######################

qmp_uci_get() {
	u="$(uci -q get qmp.$1)"
	r=$?
	echo "$u"
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci get qmp.$1)"
	qmp_debug "qmp_uci_get: uci -q get qmp.$1"
	return $r
}

qmp_uci_get_raw() {
	u="$(uci -q get $@)"
	r=$?
	echo "$u"
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci get $@)"
	qmp_debug "qmp_uci_get_raw: uci -q get $@"
	return $r
}

qmp_uci_set() {
	section="$1"
	shift
	uci -q set qmp.$section="$@" > /dev/null
	r=$?
	uci commit
	r=$(( $r + $? ))
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci set qmp.$1=$2)"
	qmp_debug "qmp_uci_set: uci -q set qmp.$1=$2"
	return $r
}

qmp_uci_set_raw() {
	local a=$(echo "$@" | cut -d= -f1)
	local b=$(echo "$@" | cut -d= -f2)
	[ -n "$b" ] && uci -q set $a="$b" || uci -q set $@ 2>/dev/null
	r=$?
	uci commit
	r=$(( $r + $? ))
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci set $@)"
	qmp_debug "qmp_uci_set_raw: uci -q set $@"
	return $r
}

qmp_uci_del() {
	uci -q delete qmp.$1
	r=$?
	uci commit
	r=$(( $r + $? ))
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci del qmp.$1)"
	qmp_debug "qmp_uci_del: uci -q del qmp.$1"
	return $r
}

qmp_uci_del_raw() {
        uci -q delete $@
	r=$?
	uci commit
	r=$(( $r + $? ))
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci del $@)"
	qmp_debug "qmp_uci_del_raw uci -q del $@"
	return $r
}

qmp_uci_add() {
	uci -q add qmp $1 > /dev/null
	r=$?
	uci commit
	r=$(( $r + $? ))
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci add qmp $1)"
	qmp_debug "qmp_uci_add: uci -q add qmp $1"
	return $r
}

qmp_uci_add_raw_get_cfg() {
	cfg=$(uci -q add $@)
	r=$?
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci add $@)"
	echo "$cfg"
	qmp_debug "qmp_uci_add_raw_get_cfg: uci -q add $@"
	return $r
}

qmp_uci_set_cfg() {
	uci -q set $@ >/dev/null
	qmp_debug "qmp_uci_set_cfg: uci -q set $@"
	return $?
}

qmp_uci_commit() {
	uci commit $1
	r=$(( $r + $? ))
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci commit $1)"
	qmp_debug "qmp_uci_commit: uci commit $1"
	return $r
}

qmp_uci_add_raw() {
	uci -q add $@ > /dev/null
	r=$?
	uci commit
	r=$(( $r + $? ))
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci add $@)"
	qmp_debug "qmp_uci_add_raw: uci -q add $@"
	return $r
}

qmp_uci_add_list_raw() {
	uci -q add_list $@ > /dev/null
	r=$?
	uci commit
	r=$(( $r + $? ))
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci add_list $@)"
	qmp_debug "qmp_uci_add_list_raw: uci -q add_list $@"
	return $r
}

qmp_uci_import() {
	cat "$1" | while read v; do
	[ ! -z "$v" ] && { uci set $v; qmp_debug "qmp_uci_import: uci set $v"; }
	done
	uci commit
	return $?
}

qmp_uci_test() {
	u="$(uci -q get $@ 2>&1)"
	r=$?
	return $r
}

##################################
# Log and errors related commnads
##################################

# Exit from execution and shows an error
# qmp_error The device is burning
qmp_error() {
	logger -s -t qMp "ERROR: $@"
	exit 1
}

# Send info to system log
# qmp_log qMp is the best
qmp_log() {
	logger -s -t qMp "$@"
}

qmp_debug() {
	[ ! -z "$DEBUG" ] &&  echo "$@" >> $DEBUG
}

#######################################
# Networking and Wifi related commands
#######################################

# Returns the names of the wifi devices from the system
qmp_get_wifi_devices() {
	awk 'NR>2 { gsub(/:$/,"",$1); print $1 }' /proc/net/wireless | grep -v -e "wlan[0-9]-[0-9]" | sort -u
}

# Returns the MAC address of the wifi devices
# (get MAC addres of the physical wifi device, if exists)
qmp_get_wifi_mac_devices() {
	for device in $(qmp_get_wifi_devices)
	do
		if [ -s "/sys/class/net/$device/phy80211/macaddress" ]
		then
			cat "/sys/class/net/$device/phy80211/macaddress"
		else
			qmp_get_mac_for_dev $device
		fi
	done
}

# Returns the device name that corresponds to the MAC address
# qmp_get_dev_from_mac 00:22:11:33:44:55
qmp_get_dev_from_mac() {
	echo "$(ip link | grep $1 -i -B1 | grep -v \@ | egrep -v "ether|mon" | grep mtu | awk '{print $2}' | tr -d : | awk NR==1)"
}

# Returns the mac address of the device
# qmp_get_mac_for_dev eth0
qmp_get_mac_for_dev() {
	mac="$(cat /sys/class/net/$1/address)"
	[ -z "$mac" ] && mac="00:00:00:00:00:00"
	echo "$mac"
}

# Returns the mac addres for specific device,, only wifi devs are allowed. Useful when eth and wlan have same MAC
# qmp_get_dev_from_wifi_mac 00:22:11:33:44:55
qmp_get_dev_from_wifi_mac() {
	for device in $(qmp_get_wifi_devices | sort)
	do
		if grep -q -i "^$1$" "/sys/class/net/$device/phy80211/macaddress" "/sys/class/net/$device/address" 2> /dev/null
		then
			echo $device
			return
		fi
	done
}

#########################
# Hooks related functions
#########################

qmp_hooks_exec() {
    local stage="$1"
	local device="none"

	[ -e /tmp/sysinfo/board_name ] && device="$(cat /tmp/sysinfo/board_name 2>/dev/null)" \
		|| device=$(cat /proc/cpuinfo | grep vendor_id | cut -d: -f2 | tr -d ' ')

    [ -z "$stage" -o -z "$device" ] && return 1
    local hooksdir="/etc/qmp/hooks/$device"

    [ -d "$hooksdir" ] && {
    for h in $hooksdir/*; do
        echo "Executing hook $h in stage $stage"
        sh $h $stage
    done
    }
}

#########################
# ID/IP commands
#########################

# Returns the crc16 from the mac of the primary mac device
# If no parameter it returns the entire hash
# If parameter = 1 or 2, returns the first/second 8bit module 256
qmp_get_crc16() {
	local mac="$(qmp_get_mac_for_dev $(qmp_uci_get node.primary_device))"
	local crc16="$(lua /usr/bin/crc16 $mac)"
	[ "$1" == "1" ] && echo -e "$crc16" | awk NR==2 && return
	[ "$1" == "2" ] && echo -e "$crc16" | awk NR==3 && return
	echo -e "$crc16" | awk NR==1
}

# qmp_get_id [8bit]
qmp_get_id() {
  local community_node_id="$(qmp_uci_get node.community_node_id)"
  [ -z "$community_node_id" ] && \
    community_node_id="$(qmp_get_crc16)"
  [ "$1" == "8bit" ] && echo "$(( 0x$community_node_id % 0x100 ))" || echo "$community_node_id"
}

# qmp_get_id_ip <1,2>
qmp_get_id_ip() {
  [ "$1" == "1" ] && echo "$(qmp_get_crc16 1)"
  [ "$1" == "2" ] && echo "$(qmp_get_crc16 2)"
}

# qmp_get_id_hostname
# returns the two last bytes of the primary MAC address
qmp_get_id_hostname() {
	local mac="$(qmp_get_mac_for_dev $(qmp_uci_get node.primary_device))"
	echo "$mac" | awk -F: '{print tolower($5)tolower($6)}'
}

#########################
# Other kind of commands
#########################

# Print the content of the parameters in reverse order (separed by spaces)
qmp_reverse_order() {
	echo "$@" | awk '{for (i=NF; i>0; i--) printf("%s ",$i);print ""}'
}

# Print the output of the command parameter in reverse order (separed by lines)
qmp_tac() {
	$@ | awk '{a[NR]=$0} END {for(i=NR;i>0;i--)print a[i]}'
}

qmp_get_dec_node_id() {
  PRIMARY_MESH_DEVICE="$(uci get qmp.interfaces.mesh_devices | awk '{print $1}')"
  LSB_PRIM_MAC="$( qmp_get_mac_for_dev $PRIMARY_MESH_DEVICE | awk -F':' '{print $6}' )"

  if qmp_uci_test qmp.node.community_node_id; then
    COMMUNITY_NODE_ID="$(uci get qmp.node.community_node_id)"
  elif ! [ -z "$PRIMARY_MESH_DEVICE" ] ; then
    COMMUNITY_NODE_ID=$LSB_PRIM_MAC
  fi
  echo $(printf %d 0x$COMMUNITY_NODE_ID)
}

# Returns the prefix /XX from netmask
qmp_get_prefix_from_netmask() {
 echo "$(ipcalc.sh 1.1.1.1 $1| grep PREFIX | cut -d= -f2)"
}

# Returns the netid from IP NETMASK
qmp_get_netid_from_network() {
 echo "$(ipcalc.sh $1 $2 | grep NETWORK | cut -d= -f2)"
}

# TO-EXPLAIN
qmp_is_in()
{
	local search="$1"
	shift
	local item
	for item in $@
	do
		if [ "$search" == "$item" ]
		then
			return 0
		fi
	done
	return 1
}
