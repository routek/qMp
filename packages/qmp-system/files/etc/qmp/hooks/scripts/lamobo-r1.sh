#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "birth" ] && {
	echo "Configuring network for Lamobo R1"
	uci set qmp.interfaces.lan_devices="eth0.1"
	uci set qmp.interfaces.wan_devices="eth0.2"
}
