#!/bin/sh
#    Copyright (C) 2011 Fundació Privada per a la Xarxa Oberta, Lliure i Neutral guifi.net
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

#######################
# UCI related commands 
#######################

qmp_uci_get() {
	u="$(uci -q get qmp.$1)"
	r=$?
	echo "$u"
	echo "$u" >> /tmp/uci_get
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci get qmp.$1)"
	return $r
}

qmp_uci_get_raw() {
	u="$(uci -q get $@)"
	r=$?
	echo "$u"
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci get $@)"
	return $r
}

qmp_uci_set() {
	uci -q set qmp.$1=$2 > /dev/null
	r=$?
	uci commit
	r=$(( $r + $? ))
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci set qmp.$1=$2)"
	return $r
}

qmp_uci_set_raw() {                      
	uci -q set $@ > /dev/null
	r=$?                         
	uci commit                   
	r=$(( $r + $? ))  
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci set $@)"
        return $r                    
}           

qmp_uci_add() {
	uci -q add qmp $1 > /dev/null
	r=$?
	uci commit
	r=$(( $r + $? ))
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci add qmp $1)"
	return $r
}

qmp_uci_add_raw() {
	uci -q add $@ > /dev/null
	r=$? 
	uci commit
	r=$(( $r + $? ))
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci add $@)"
	return $r 
}

qmp_uci_add_list_raw() {
	uci -q add_list $@ > /dev/null
	r=$?                                                              
	uci commit                                                            
	r=$(( $r + $? ))                                                      
	[ $r -ne 0 ] && logger -t qMp "UCI returned an error (uci add_list $@)"    
	return $r
}

qmp_uci_import() {
	cat "$1" | while read v; do
	[ ! -z "$v" ] && uci set $v
	done
	uci commit
	return $?       
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

#######################################
# Networking and Wifi related commands
#######################################

# Returns the names of the wifi devices from the system
qmp_get_wifi_devices() {
	echo "$(ip link | grep  -E ": (wifi|wlan).: "| cut -d: -f2)"
}

# Returns the MAC address of the wifi devices
qmp_get_wifi_mac_devices() {
	echo "$(ip link | grep -A1 -E ": (wifi|wlan).: " | grep link | cut -d' ' -f6)"
}

# Returns the device name that corresponds to the MAC address
# qmp_get_dev_from_mac 00:22:11:33:44:55
qmp_get_dev_from_mac() {
        ip l | grep $1 -i -B1 | grep -v \@ | grep -v ether | awk '{print $2}' | tr -d : | awk NR==1
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

