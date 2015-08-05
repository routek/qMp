#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "firstboot" ] && {

echo "Configuring TPlink WDR switch networking"
iseth=0

devs="$(uci get qmp.interfaces.lan_devices) \
 $(uci get qmp.interfaces.wan_devices) \
 $(uci get qmp.interfaces.mesh_devices) \
 $(uci get qmp.interfaces.ignore_devices)"

for d in $devs
	do
	[ "$d" == "eth0" ] && iseth=1 && break
done

[ $iseth -eq 0 ] && {
	echo "Device eth0 not configured, doing it..."
	uci set qmp.interfaces.lan_devices="eth0.1"
	uci set qmp.interfaces.mesh_devices="eth0.12"
	uci set qmp.interfaces.wan_devices="eth0.2"
	uci set qmp.interfaces.no_vlan_devices="eth0.12"
	uci set qmp.interfaces.ignore_devices="eth0"
	uci commit qmp
	}
}
