#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "birth" ] && {
	uci -q delete network.@switch[0]
	uci -q delete network.@switch_vlan[2]
	uci -q delete network.@switch_vlan[1]
	uci -q delete network.@switch_vlan[0]
}

[ "$STAGE" == "firstboot" ] && {

[ "$(uci -q get network.@switch[0].name)" == "eth0" ] && {
	echo "Switch already configured"
	exit 0
	}

echo "Configuring TPlink WDR switch [INET|LAN|LAN|LAN|MESH]"

uci -q delete network.@switch[0]
uci add network switch

uci -q delete network.@switch_vlan[2]
uci -q delete network.@switch_vlan[1]
uci -q delete network.@switch_vlan[0]

uci add network switch_vlan > /dev/null
uci add network switch_vlan > /dev/null
uci add network switch_vlan > /dev/null

uci set network.@switch[0]=switch
uci set network.@switch[0].name=switch0
uci set network.@switch[0].reset=1
uci set network.@switch[0].enable_vlan=1
uci set network.@switch_vlan[0]=switch_vlan
uci set network.@switch_vlan[0].device=switch0
uci set network.@switch_vlan[0].vlan=1
uci set network.@switch_vlan[0].vid=1
uci set network.@switch_vlan[0].ports="0t 2 3 4"
uci set network.@switch_vlan[1]=switch_vlan
uci set network.@switch_vlan[1].device=switch0
uci set network.@switch_vlan[1].vlan=2
uci set network.@switch_vlan[1].vid=2
uci set network.@switch_vlan[1].ports="0t 1"
uci set network.@switch_vlan[2]=switch_vlan
uci set network.@switch_vlan[2].device=switch0
uci set network.@switch_vlan[2].vlan=12
uci set network.@switch_vlan[2].vid=12
uci set network.@switch_vlan[2].ports="0t 5t"

uci commit network
}
