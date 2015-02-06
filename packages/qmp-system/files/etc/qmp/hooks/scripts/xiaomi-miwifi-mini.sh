#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "birth" ] && {
	echo "Configuring network for Xiaomi MiWiFi Mini"
	uci set qmp.interfaces.lan_devices="eth0.1"
	uci set qmp.interfaces.wan_devices="eth0.2"
	uci set qmp.interfaces.ignore_devices="eth0"
	uci add qmp wireless
	uci set qmp.@wireless[0]=wireless
	uci set qmp.@wireless[0].mode=adhoc
	uci set qmp.@wireless[0].device=wlan0
	uci add qmp wireless
	uci set qmp.@wireless[1]=wireless
	uci set qmp.@wireless[1].mode=80211s_aplan
	uci set qmp.@wireless[1].device=wlan1
	uci commit qmp	
}
