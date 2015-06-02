#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "birth" ] && {
	echo "Configuring network and wifi for Comfast CF-WR800N"
        uci set qmp.interfaces.lan_devices="eth0.1"
        uci set qmp.interfaces.ignore_devices="eth0"
	uci add qmp wireless
	uci set qmp.@wireless[0]=wireless
	uci set qmp.@wireless[0].mode=80211s_aplan
	uci set qmp.@wireless[0].device=wlan0
	uci commit qmp
}
