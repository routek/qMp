#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "birth" ] && {
	echo "Configuring eth0 as wan and eth1 as lan"
	uci set qmp.interfaces.lan_devices="eth1"
	uci set qmp.interfaces.wan_devices="eth0"
	uci commit qmp
}
