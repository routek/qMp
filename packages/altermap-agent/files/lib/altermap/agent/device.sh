#!/bin/sh
# Copyleft 2012 Gui Iribarren <gui@altermundi.net>
# This is free software, licensed under the GNU General Public License v3.

. /lib/altermap/functions.sh

read_hardware () {
  cat /tmp/sysinfo/model
}

read_firmware () {
  . /etc/openwrt_release
  echo "$DISTRIB_DESCRIPTION"
}

device_json () {
  json_init
  json_add_string collection "devices"
  json_add_string hostname "$(read_hostname)"
  json_add_string hardware "$(read_hardware)"
  json_add_string firmware "$(read_firmware)"
  json_dump
}

update_device () {
  node_id="$(get_id node)"
  [ -n "$node_id" ] || return

  json_load "$(device_json)"
  json_add_string node_id "$node_id"

  device_id="$(read_device_id)"
  if [ -n "$device_id" ] ; then
    action=PUT
    rev="$(get_rev "$device_id")"
    [ -n "$rev" ] \
      && json_add_string _rev "$rev"
  else
    action=POST
  fi

  reply="$(query_server $action "/$device_id" "$(json_dump)")"
  json_init; json_load "$reply"
  [ -n "$DEBUG" ] && json_dump >&2
  json_get_vars id ok
  [ "$ok" == 1 ] && save_device_id "$id"
}

run_hook () {
  update_device
}
