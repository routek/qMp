#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "birth" ] && {
	echo "Configuring ramips wifi as 802.11s mesh and AP LAN"
	uci add qmp wireless
	uci set qmp.@wireless[0]=wireless
	uci set qmp.@wireless[0].mode=80211s_aplan
	uci set qmp.@wireless[0].device=wlan0
	uci commit qmp
}
