#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "birth" ] && {
	echo "Configuring Ethernet and Wireless for MicroWRT"

        uci -q delete network.@switch[0]
        uci -q delete network.@switch_vlan[2]
        uci -q delete network.@switch_vlan[1]
        uci -q delete network.@switch_vlan[0]
	uci commit network

	uci add network switch
	uci add network switch_vlan > /dev/null

	uci set network.@switch[0]=switch
	uci set network.@switch[0].name=switch0
	uci set network.@switch[0].reset=1
	uci set network.@switch[0].enable_vlan=1
	uci set network.@switch_vlan[0]=switch_vlan
	uci set network.@switch_vlan[0].device=switch0
	uci set network.@switch_vlan[0].vlan=1
	uci set network.@switch_vlan[0].vid=1
	uci set network.@switch_vlan[0].ports="4 6t"
	uci commit network

	uci set qmp.interfaces.lan_devices="eth0.1"
	uci set qmp.interfaces.mesh_devices="eth0.12"
	uci set qmp.interfaces.no_vlan_devices="eth0.12"
        uci set qmp.interfaces.ignore_devices="eth0"
	
	uci add qmp wireless
	uci set qmp.@wireless[0]=wireless
	uci set qmp.@wireless[0].mode=80211s_aplan
	uci set qmp.@wireless[0].device=wlan0
	uci commit qmp
}
