#!/bin/sh
# Copyleft 2012 Gui Iribarren <gui@altermundi.net>
# This is free software, licensed under the GNU General Public License v3.

. /lib/altermap/functions.sh
. /lib/json/ieee80211.sh

get_interfaces_json () {
  query_server POST /_design/altermap/_view/interfacesByDeviceId \
                    '{"keys":["'$(read_device_id)'"]}'
}

update_interfaces () {
  del_interfaces
  add_interfaces
}

del_interfaces () {
  device_id="$(read_device_id)"
  [ -n "$device_id" ] || return
  for id in $(get_ids interfaces) ; do
    query_server DELETE "/${id}?rev=$(get_rev $id)"
  done
}

add_interfaces () {
  device_id="$(read_device_id)"
  [ -n "$device_id" ] || return
  local IFS=$NEWLINE
  for line in $(ieee80211_interfaces_json) ; do
    json_init
    json_load "$line"
    json_add_string device_id "$device_id"
    json_add_string collection "interfaces"
    json_add_string medium "wireless"
    query_server POST / "$(json_dump)"
  done
  unset IFS
}

run_hook () {
  update_interfaces
}
