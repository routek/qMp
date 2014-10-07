#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "birth" ] && {
	uci -q delete network.@switch[0]
	while uci -q delete network.@switch_vlan[0]; do :; done
}

[ "$STAGE" == "firstboot" ] && {

	echo "Configuring TP-Link TL-WDR4900-v1 switch"

	uci -q delete network.@switch[0]
	while uci -q delete network.@switch_vlan[0]; do :; done

	uci add network switch
	uci set network.@switch[0]=switch
	uci set network.@switch[0].name=switch0
	uci set network.@switch[0].reset=1
	uci set network.@switch[0].enable_vlan=1

	uci add network switch_vlan > /dev/null
	uci set network.@switch_vlan[0]=switch_vlan
	uci set network.@switch_vlan[0].device=switch0
	uci set network.@switch_vlan[0].vlan=1
	uci set network.@switch_vlan[0].vid=1
	uci set network.@switch_vlan[0].ports="0t 1"

	uci add network switch_vlan > /dev/null
	uci set network.@switch_vlan[1]=switch_vlan
	uci set network.@switch_vlan[1].device=switch0
	uci set network.@switch_vlan[1].vlan=2
	uci set network.@switch_vlan[1].vid=2
	uci set network.@switch_vlan[1].ports="0t 2"

	uci add network switch_vlan > /dev/null
	uci set network.@switch_vlan[2]=switch_vlan
	uci set network.@switch_vlan[2].device=switch0
	uci set network.@switch_vlan[2].vlan=3
	uci set network.@switch_vlan[2].vid=3
	uci set network.@switch_vlan[2].ports="0t 3"

	uci add network switch_vlan > /dev/null
	uci set network.@switch_vlan[3]=switch_vlan
	uci set network.@switch_vlan[3].device=switch0
	uci set network.@switch_vlan[3].vlan=4
	uci set network.@switch_vlan[3].vid=4
	uci set network.@switch_vlan[3].ports="0t 4"

	uci add network switch_vlan > /dev/null
	uci set network.@switch_vlan[4]=switch_vlan
	uci set network.@switch_vlan[4].device=switch0
	uci set network.@switch_vlan[4].vlan=5
	uci set network.@switch_vlan[4].vid=5
	uci set network.@switch_vlan[4].ports="0t 5"

	uci commit network
}
