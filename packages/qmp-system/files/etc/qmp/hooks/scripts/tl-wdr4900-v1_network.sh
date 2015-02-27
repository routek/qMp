#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "firstboot" ] && {

	echo "Configuring TP-Link TL-WDR4900-v1 Ethernet networking"

	uci set qmp.interfaces.switch_devices="eth0.1 eth0.2 eth0.3 eth0.4 eth0.5"
	uci set qmp.interfaces.switch_devices_names="Internet Ethernet1 Ethernet2 Ethernet3 Ethernet4"
	uci set qmp.interfaces.lan_devices="eth0.2 eth0.3 eth0.4 eth0.5"
	uci set qmp.interfaces.wan_devices="eth0.1"
	uci set qmp.interfaces.ignore_devices="eth0"

	uci commit qmp
}
