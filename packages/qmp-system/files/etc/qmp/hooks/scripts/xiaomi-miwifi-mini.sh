#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "birth" ] && {
	echo "Configuring wifi for Xiaomi MiWiFi Mini"
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
