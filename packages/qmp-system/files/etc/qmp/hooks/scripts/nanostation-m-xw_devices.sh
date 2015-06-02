#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "birth" ] && {
	echo "Configuring Ethernet switched Main and Secondary ports for NSM5-XW"
	uci set qmp.interfaces.lan_devices="eth0.1"
	uci set qmp.interfaces.wan_devices="eth0.2"
        uci set qmp.interfaces.ignore_devices="eth0"
	uci add qmp wireless
	uci set qmp.@wireless[0]=wireless
	uci set qmp.@wireless[0].mode=adhoc
	uci set qmp.@wireless[0].device=wlan0
	uci commit qmp
}
