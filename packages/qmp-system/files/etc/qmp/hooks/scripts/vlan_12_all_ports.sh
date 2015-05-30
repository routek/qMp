#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "birth" ] && {
        echo "Configuring mesh in all Ethernet ports"
        uci set qmp.interfaces.mesh_devices="eth0.12"
        uci set qmp.interfaces.no_vlan_devices="eth0.12"
        uci commit qmp
}


[ "$STAGE" == "firstboot" ] && {

	echo "Configuring VLAN 12 on all ports, tagged"

	uci add network switch_vlan
	uci set network.@switch_vlan[-1]=switch_vlan
	uci set network.@switch_vlan[-1].device=switch0
	uci set network.@switch_vlan[-1].vlan=12
	uci set network.@switch_vlan[-1].ports="0t 1t 2t 3t 4t 6t"
	uci commit
}
