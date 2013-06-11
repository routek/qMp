#!/bin/sh
# Copyleft 2012 Gui Iribarren <gui@altermundi.net>
# This is free software, licensed under the GNU General Public License v3.

. /usr/share/libubox/jshn.sh

NEWLINE="
"

read_server_url () {
  uci -q get altermap.agent.server_url
}

read_network_name () {
  uci -q get altermap.agent.network
}

read_hostname () {
  uci -q get system.@system[0].hostname
}

read_node_name () {
  echo $(read_hostname | sed "s/--.*$//")
}

read_device_id () {
  uci -q get altermap.agent.device_id
}

save_device_id () {
  uci set altermap.agent.device_id="$1"
  uci commit altermap
}

get_network_json () {
  query_server POST /_design/altermap/_view/networkByName \
                    '{"keys":["'$(read_network_name)'"]}'
 }

get_node_json () {
  query_server POST /_design/altermap/_view/nodeByNetIdAndName \
                    '{"keys":[["'$(get_id network)'", "'$(read_node_name)'"]]}'
}

get_id () {
  get_ids "$@" | head -n 1
}

get_ids () {
  local i=0
  reply="$(get_${1}_json)" || return
  json_init; json_load "$reply"
  json_select rows
  while i=$(($i+1)) ; do
    json_get_type type $i
    [ "$type" != "object" ] && break
    json_select $i
    json_get_vars id
    echo "$id"
    json_select ..
  done
}

get_rev () {
  reply="$(query_server GET "/$1")" || return
  json_init; json_load "$reply"
  json_get_vars _rev
  echo "$_rev"
}

query_server () { action="$1" ; url="${2#/}" ; shift 2; query="$@"
  [ -n "$DEBUG" ] && echo curl "$action" "/$url" "$query" >&2
  curl -s -X $action "$(read_server_url)/$url" \
       -H "Content-Type: application/json" \
       -d "$query"
}
