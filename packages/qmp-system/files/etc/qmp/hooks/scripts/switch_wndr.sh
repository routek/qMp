#!/bin/sh
# Stage = [birth|firstboot|anyboot|preconf|postconf]
STAGE="$1"

[ "$STAGE" == "birth" ] && {

echo "Disabling Netgear wndr3700 switch"

uci -q delete network.@switch[0]
uci -q delete network.@switch_vlan[2]
uci -q delete network.@switch_vlan[1]
uci -q delete network.@switch_vlan[0]

uci commit network
}
