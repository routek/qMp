#!/bin/sh
# Copyleft 2012 Gui Iribarren <gui@altermundi.net>
# This is free software, licensed under the GNU General Public License v3.

. /usr/share/libubox/jshn.sh

interfaces_json () {
  net_dir="/sys/class/net"
  for interface in $(cd $net_dir; ls -d * 2>/dev/null) ; do
    json_init
    json_add_object "$phy"
    json_load "$(ubus call network.device status '{ "name": "'$phy'" }')"
    json_close_object
    json_dump
  done
}
