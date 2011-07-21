#!/bin/sh

qmp_uci_get() {
	u="$(uci -q get qmp.$1)"
	r=$?
	echo "$u"
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

qmp_uci_import() {
	cat "$1" | while read v; do
	[ ! -z "$v" ] && uci set $v
	done
	uci commit
	return $?       
}

qmp_error() {
	logger -s -t qMp "ERROR: $1"
	exit 1
}

qmp_get_wifi_devices() {
	echo "$(ip link | grep  -E ": (wifi|wlan).: "| cut -d: -f2)"
}

qmp_get_wifi_mac_devices() {
	echo "$(ip link | grep -A1 -E ": (wifi|wlan).: " | grep link | cut -d' ' -f6)"
}

qmp_get_dev_from_mac() {
        ip l | grep $1 -i -B1 | grep -v \@ | grep -v ether | awk '{print $2}' | tr -d :            
}          
reverse_order() {
	echo "$@" | awk '{for (i=NF; i>0; i--) printf("%s ",$i);print ""}'
}

