#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "birth" ] && {
	echo "Configuring network port roles for Lamobo R1"
	uci set qmp.interfaces.lan_devices="eth0.1 eth0.2 eth0.3 eth0.4"
	uci set qmp.interfaces.wan_devices="eth0.5"
	uci set qmp.interfaces.ignore_devices="eth0"

        echo "Configuring mesh in all Ethernet ports"
        uci set qmp.interfaces.mesh_devices="eth0.12"
        uci set qmp.interfaces.no_vlan_devices="eth0.12"

	uci commit qmp
}

[ "$STAGE" == "firstboot" ] && {

	echo "Configuring Lamobo R1 switch"

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
	uci set network.@switch_vlan[0].ports="8t 2"

	uci add network switch_vlan > /dev/null
	uci set network.@switch_vlan[1]=switch_vlan
	uci set network.@switch_vlan[1].device=switch0
	uci set network.@switch_vlan[1].vlan=2
	uci set network.@switch_vlan[1].vid=2
	uci set network.@switch_vlan[1].ports="8t 1"

	uci add network switch_vlan > /dev/null
	uci set network.@switch_vlan[2]=switch_vlan
	uci set network.@switch_vlan[2].device=switch0
	uci set network.@switch_vlan[2].vlan=3
	uci set network.@switch_vlan[2].vid=3
	uci set network.@switch_vlan[2].ports="8t 0"

	uci add network switch_vlan > /dev/null
	uci set network.@switch_vlan[3]=switch_vlan
	uci set network.@switch_vlan[3].device=switch0
	uci set network.@switch_vlan[3].vlan=4
	uci set network.@switch_vlan[3].vid=4
	uci set network.@switch_vlan[3].ports="8t 4"

	uci add network switch_vlan > /dev/null
	uci set network.@switch_vlan[4]=switch_vlan
	uci set network.@switch_vlan[4].device=switch0
	uci set network.@switch_vlan[4].vlan=5
	uci set network.@switch_vlan[4].vid=5
	uci set network.@switch_vlan[4].ports="8t 3"

	uci add network switch_vlan > /dev/null
	uci set network.@switch_vlan[5]=switch_vlan
	uci set network.@switch_vlan[5].device=switch0
	uci set network.@switch_vlan[5].vlan=12
	uci set network.@switch_vlan[5].vid=12
	uci set network.@switch_vlan[5].ports="8t 0t 1t 2t 3t 4t"
	
	uci commit network
}
