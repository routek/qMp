#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "birth" ] && {
	echo "Configuring switched Ethernet Main and Secondary ports for Unifi AP-PRO"
	uci set qmp.interfaces.lan_devices="eth0.1"
	uci set qmp.interfaces.wan_devices="eth0.2"
        uci set qmp.interfaces.ignore_devices="eth0"
	uci commit qmp
}
