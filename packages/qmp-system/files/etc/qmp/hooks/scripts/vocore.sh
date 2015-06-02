#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "birth" ] && {
	echo "Configuring network and wifi for VoCore"
	uci set qmp.interfaces.lan_devices="eth0.1"
	uci set qmp.interfaces.ignore_devices="eth0"
	uci add qmp wireless
	uci set qmp.@wireless[0]=wireless
	uci set qmp.@wireless[0].mode=adhoc
	uci set qmp.@wireless[0].device=wlan0
	uci commit qmp
}
