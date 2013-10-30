#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "firstboot" ] && {

[ "$(uci -q get network.@switch[0].name)" == "eth0" ] && {
	echo "Switch already configured"
	exit 0
	}

echo "Configuring TPlink WR-841n-V8 switch [LAN|LAN|LAN|LAN]"

uci -q delete network.@switch[0]
uci add network switch

uci -q delete network.@switch_vlan[2]
uci -q delete network.@switch_vlan[1]
uci -q delete network.@switch_vlan[0]

uci add network switch_vlan > /dev/null

uci set network.@switch[0]=switch
uci set network.@switch[0].name=switch0
uci set network.@switch[0].reset=1
uci set network.@switch[0].enable_vlan=1
uci set network.@switch_vlan[0]=switch_vlan
uci set network.@switch_vlan[0].device=switch0
uci set network.@switch_vlan[0].vlan=1
uci set network.@switch_vlan[0].vid=1
uci set network.@switch_vlan[0].ports="0 1 2 3 4"

uci commit network
}
