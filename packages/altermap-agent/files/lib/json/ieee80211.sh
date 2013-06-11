#!/bin/sh
# Copyleft 2012 Gui Iribarren <gui@altermundi.net>
# This is free software, licensed under the GNU General Public License v3.

. /usr/share/libubox/jshn.sh

ieee80211_interfaces_json () {
  ieee80211_dir="/sys/kernel/debug/ieee80211"
  for path in $ieee80211_dir/*/netdev\:*/ ; do
    eval $(echo $path | sed -r "s|$ieee80211_dir/(.*)/netdev:(.*)/|phy=\1 interface=\2|")
    macaddr="$(cat /sys/class/net/$interface/address)"
    mode="$(iw $interface info |sed -r "s/.*type (.*)/\1/p;d")"
    json_init
    json_add_string name $interface
    json_add_string phydev $phy
    json_add_string macaddr $macaddr
    json_add_string mode $mode
    json_dump
    json_dump >&2
  done
}

ieee80211_stations_json () {
  ieee80211_dir="/sys/kernel/debug/ieee80211"
  for path in $ieee80211_dir/*/netdev\:*/stations/*/last_signal ; do
    eval $(echo $path | sed -r "s|$ieee80211_dir/(.*)/netdev:(.*)/stations/(.*)/last_signal|phy=\1 interface=\2 station=\3|")
    macaddr="$(cat /sys/class/net/$interface/address)"
    signal="$(cat $path)"
    channel="$(iw $interface info | sed -r "s/.*channel (\w*) .*/\1/p;d")"
    json_init
    json_add_string macaddr $macaddr
    json_add_string station $station
    json_add_object attributes
    json_add_string signal $signal
    json_add_string channel $channel
    json_close_object
    json_dump
    json_dump >&2
  done
}
