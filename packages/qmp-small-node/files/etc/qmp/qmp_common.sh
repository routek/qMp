#!/bin/sh

qmp_uci_get() {
	echo "$(uci get qmp.$1 2>/dev/null)"
}

qmp_uci_set() {
	uci set qmp.$1=$2
	uci commit
}

qmp_uci_add() {
	uci add qmp $1
	uci commit
}

qmp_error() {
	echo "Error: $1"
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

