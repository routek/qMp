#!/bin/sh
#/etc/rc.common
#    Copyright (C) 2011 Fundacio Privada per a la Xarxa Oberta, Lliure i Neutral guifi.net
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#    The full GNU General Public License is included in this distribution in
#    the file called "COPYING".
#
# Contributors:
#	Simó Albert i Beltran
#

QMP_PATH="/etc/qmp"
SOURCE_NETWORK=1

#######################
# Importing files
######################
. $QMP_PATH/qmp_common.sh
[ -z "$SOURCE_GW" ] && . $QMP_PATH/qmp_gw.sh

# requires ip ipv6calc awk sed grep

qmp_get_llocal_for_dev() {
  local dev=$1
  ip a show dev $dev | grep inet6 | awk '{print $2}'
}

# returns primary device
qmp_get_primary_device() {
  local primary_mesh_device="$(uci get qmp.node.primary_device)"
  [ -z "$primary_mesh_device" ] && 
      {
      if ip link show dev eth0 > /dev/null; then
        primary_mesh_device="eth0"
      else
        primary_mesh_device="$(ip link show | awk '!/lo:/&&/^[0-9]?:/{sub(/:$/,"",$2); print $2; exit}')"
      fi
      [ -z "$primary_mesh_device" ] && echo "CRITICAL: No primary network device found, please define qmp.node.primary_device" 
      }
  echo "$primary_mesh_device"
}

# arg1=<mesh|lan|wan>, returns the devices which have to be configured in such mode
qmp_get_devices() {
  local devices=""

  if [ "$1" == "mesh" ]; then 
    local brlan_enabled=0
    for dev in $(uci get qmp.interfaces.mesh_devices 2>/dev/null); do

        # Lookging if device is defined as LAN, in such case dev=br-lan, but only once
        for landev in $(uci get qmp.interfaces.lan_devices 2>/dev/null); do
            if [ "$landev" == "$dev" ]; then
                if [ $brlan_enabled -eq 0 ]; then
                    dev="br-lan"
                    brlan_enabled=1
                    break
                else
                    dev=""
                    break
                fi
            fi
        done

      [ -n "$dev" ] && devices="$devices $dev"
    done
  fi

  if [ "$1" == "lan" ]; then
     devices="$(uci get qmp.interfaces.lan_devices 2>/dev/null)"
  fi

  if [ "$1" == "wan" ]; then
     devices="$(uci get qmp.interfaces.wan_devices 2>/dev/null)"
  fi

  echo "$devices"
}


qmp_get_rescue_ip() {
	local device=$1
	[ -z "$device" ] && return 1

	local rprefix=$(uci get qmp.networks.rescue_prefix24 2>/dev/null)
	[ -z "$rprefix" ] && return 0

	local mac=$(ip addr show dev $device | grep -m 1 "link/ether" | awk '{print $2}')
	[ -z "$mac" ] && return 2
	
	#local xoctet=$(printf "%d\n" 0x$(echo $mac | cut -d: -f5))
	local yoctet=$(printf "%d\n" 0x$(echo $mac | cut -d: -f6))
	local rip="$rprefix.$yoctet.1"

	echo "$rip"
}

qmp_attach_device_to_interface() {
	local device=$1
	local conf=$2
	local interface=$3
	local wifi_config="$(uci -qX show wireless | sed -n -e "s/wireless\.\([^\.]\+\)\.device=$device/\1/p")"
	if [ -n "$wifi_config" -a "wifi-iface" = "$(uci -q get wireless.$wifi_config)" ] ; then
		uci set wireless.$wifi_config.network="$interface"
		uci commit wireless
	else
		uci add_list $conf.$interface.ifname="$device"
	fi
}

qmp_configure_rescue_ip() {
	local device=$1
	[ -z "$device" ] && return 1
	
	local rip="$(qmp_get_rescue_ip $device)"
	[ -z "$rip" ] && { echo "Cannot get rescue IP for device $device"; return 1; }
	
	echo "Rescue IP for device $device is $rip"	

	local conf="network"

	uci set $conf.${device}_rescue="interface"
	qmp_attach_device_to_interface $device $conf ${device}_rescue
	uci set $conf.${device}_rescue.proto="static"
	uci set $conf.${device}_rescue.ipaddr="$rip"
	uci set $conf.${device}_rescue.netmask="255.255.255.248"
	uci commit $conf
}

qmp_get_ip6_slow() {
  local addr_prefix="$1"
  local addr="$(echo $addr_prefix | awk -F'/' '{print $1}')"
  local mask="$(echo $addr_prefix | awk -F'/' '{print $2}')"

  echo "qmp_get_ip6_slow addr_prefix=$addr_prefix addr=$addr mask=$mask" 1>&2

  if [ -z "$mask" ] ; then
    mask="128"
  fi

  local addr_in=$addr
  local addr_out=""
  local found=0

  while ! [ -z "$addr_in" ] ; do

    addr_in=$( echo $addr_in | sed -e "s/^://g" )

    if echo "$addr_in" | grep "^:"  >/dev/null 2>&1 ; then

      if echo "$addr_in" | grep "::"  >/dev/null 2>&1 ; then
        echo "Invalid 1 IPv6 address $addr_prefix" 1>&2
        return 1
      fi

      addr_in=$( echo $addr_in | sed -e "s/^://g" )

      if [ -z "$addr_in" ] ; then
        addr_out="$addr_out::"
      else
        addr_out="$addr_out:"
      fi

    else

      local addr16="$(echo $addr_in | awk -F':' '{print $1}')"
      addr_in=$( echo $addr_in | sed -e "s/^$addr16//g" )

      if [ -z "$addr_out" ] ; then
	addr_out="$addr16"
      else
	addr_out="$addr_out:$addr16"
      fi

      if echo "$addr16" | grep '\.'  >/dev/null 2>&1 ; then
        found=$(( $found + 2 ))
      else
        found=$(( $found + 1 ))
      fi

    fi

  done

  if echo $addr_out | grep "::" >/dev/null 2>&1 && [ "$found" -lt "8" ] ; then

    local insert="0"
    for n in $( seq $found "6" ) ; do
      insert="$insert:0"
    done

    addr_out=$( echo $addr_out | sed -e "s/^::$/$insert/g" )
    addr_out=$( echo $addr_out | sed -e "s/^::/$insert:/g" )
    addr_out=$( echo $addr_out | sed -e "s/::$/:$insert/g" )
    addr_out=$( echo $addr_out | sed -e "s/::/:$insert:/g" )

  elif echo $addr_out | grep "::"  >/dev/null 2>&1 || [ "$found" != "8" ] ; then
    echo "Invalid 2 IPv6 address $addr_prefix found=$found" 1>&2
    return 1
  fi


#  echo "Correct IPv6 address $addr_prefix addr_out=$addr_out found=$found" 1>&2

  local pos=0
  addr_in=$addr_out
  addr_out=""

  while ! [ -z "$addr_in" ] ; do

    addr_in=$( echo $addr_in | sed -e "s/^://g" )

    local addr16="$( echo $addr_in | awk -F':' '{print $1}' )"
    addr_in=$( echo $addr_in | sed -e "s/^$addr16//g" )

    if echo $addr16 | grep '\.' >/dev/null 2>&1  ; then
      local ip1=$( echo $addr16 | awk -F'.' '{print $1}' )
      local ip2=$( echo $addr16 | awk -F'.' '{print $2}' )
      local ip3=$( echo $addr16 | awk -F'.' '{print $3}' )
      local ip4=$( echo $addr16 | awk -F'.' '{print $4}' )

#      echo "addr16=$addr16 ip1=$ip1 ip2=$ip2 ip3=$ip3 ip4=$ip4" 1>&2

      addr16=$( printf "%X" $(( $(( $ip1 * 0x100 )) + $ip2 )) )

      if [ -z "$ip4" ] ; then
        echo "Invalid 3 IPv6 address $addr_prefix" 1>&2
        return 1
      fi

      addr_in=$( printf "%X" $(( $(( $ip3 * 0x100 )) + $ip4 )) )$addr_in


    fi

    local prefix16
    if [ "$pos" -le "$mask" ] ; then

      if [ "$(( $pos + 16 ))" -le "$mask" ] ; then
	prefix16=$addr16
      else
	prefix16=$( printf "%X" $(( 0x$addr16 & 0xFFFF<<$(( $(( $pos + 16 )) - $mask )) )) )
      fi

    else
      prefix16="0"
    fi


    if [ -z "$addr_out" ] ; then
      addr_out="$prefix16"
    else
      addr_out="$addr_out:$prefix16"
    fi

    pos=$(( $pos + 16 ))

  done

  echo "$addr_out"
}







qmp_get_ip6_fast() {

  if ! [ -x /usr/bin/ipv6calc ] ; then
     qmp_get_ip6_slow $1
     return $?
  fi

  local addr_prefix="$1"
  local addr="$(echo $addr_prefix | awk -F'/' '{print $1}')"
  local mask="$(echo $addr_prefix | awk -F'/' '{print $2}')"

  if [ -z "$mask" ] ; then
    echo "qmp_get_ip6_fast: ERROR addr_prefix=$addr_prefix addr_long=$addr_long  addr=$fake_long mask=$mask" 1>&2
    return 1
    mask="128"
  fi

  local addr_long=$( ipv6calc -q  --in ipv6 $addr --showinfo -m 2>&1 | grep IPV6= | awk -F'=' '{print $2}' )

  local fake_prefix16="20a2" # original input is manipulated because ipv6calc complains about reserved ipv6 addresses
  local addr_prefix16="$(echo $addr_long | awk -F':' '{print $1}')"
  local fake_long=$( echo $addr_long | sed -e "s/^$addr_prefix16/$fake_prefix16/g" )
  local fake_out

#  echo "qmp_get_ip6_fast: begin addr_prefix=$addr_prefix addr_long=$addr_long  addr=$fake_long mask=$mask" 1>&2

  if [ "$mask" -ge "0" ] &&  [ "$mask" -le "112" ] && [ "$(( $mask % 16))" = "0" ]; then

    fake_out="$( ipv6calc --in ipv6 $fake_long/$mask -F --printprefix --out ipv6addr 2>/dev/null )::/$mask"

  else

    if [ "$(( $mask % 16))" != "0" ]; then
      echo "ERROR addr_prefix=$1 mask=$mask must be multiple of 16" 1>&2
      return 1
    fi

    fake_out="$( ipv6calc --in ipv6 $fake_long/128 -F --printprefix --out ipv6addr 2>/dev/null )"
  fi

  echo $fake_out | sed -e "s/^$fake_prefix16/$addr_prefix16/g"

#  echo "qmp_get_ip6_fast: return addr_prefix=$addr_prefix addr_long=$addr_long  addr=$fake_long mask=$mask" 1>&2
}








qmp_calculate_ula96() {

  local prefix=$1
  local mac=$2
  local suffix=$3

  local prefix48=$( qmp_get_ip6_fast $prefix/128 )
  local suffix48=$( qmp_get_ip6_fast $suffix/128 )

# echo "qmp_calculate_ula96 suffix48=$suffix48" 1>&2

  local mac1="$( echo $mac | awk -F':' '{print $1}' )"
  local mac2="$( echo $mac | awk -F':' '{print $2}' )"
  local mac3="$( echo $mac | awk -F':' '{print $3}' )"
  local mac4="$( echo $mac | awk -F':' '{print $4}' )"
  local mac5="$( echo $mac | awk -F':' '{print $5}' )"
  local mac6="$( echo $mac | awk -F':' '{print $6}' )"

  local p1="$( echo $prefix48 | awk -F':' '{print $1}' )"
  local p2="$( echo $prefix48 | awk -F':' '{print $2}' )"
  local p3="$( echo $prefix48 | awk -F':' '{print $3}' )"

  local s1="$( echo $suffix48 | awk -F':' '{print $7}' )"
  local s2="$( echo $suffix48 | awk -F':' '{print $8}' )"

  printf "%X:%X:%X:%X:%X:%X:%X:%X\n" 0x$p1 0x$p2 0x$p3  $(( ( 0x$mac1 * 0x100 ) + 0x$mac2 ))  $(( ( 0x$mac3 * 0x100 ) + 0x$mac4 ))  $(( ( 0x$mac5 * 0x100 ) + 0x$mac6 ))  0x$s1 0x$s2

}



qmp_calculate_addr64() {

  local prefix=$1
  local node=$2
  local suffix=$3

  local prefix48=$( qmp_get_ip6_fast $prefix/128 )
  local suffix48=$( qmp_get_ip6_fast $suffix/128 )

  local p1="$( echo $prefix48 | awk -F':' '{print $1}' )"
  local p2="$( echo $prefix48 | awk -F':' '{print $2}' )"
  local p3="$( echo $prefix48 | awk -F':' '{print $3}' )"

  local s5="$( echo $suffix48 | awk -F':' '{print $5}' )"
  local s6="$( echo $suffix48 | awk -F':' '{print $6}' )"
  local s7="$( echo $suffix48 | awk -F':' '{print $7}' )"
  local s8="$( echo $suffix48 | awk -F':' '{print $8}' )"

  printf "%X:%X:%X:%X:%X:%X:%X:%X\n" 0x$p1 0x$p2 0x$p3   0x$node   0x$s5 0x$s6 0x$s7 0x$s8

}



qmp_get_ula96() {

  local prefix=$1
  local dev_mac=$2
  local suffix=$3
  local mask=$4

  local mac=$( qmp_get_mac_for_dev $dev_mac )
  local ula96=$( qmp_calculate_ula96 $prefix $mac $suffix )

  if [ -z "$mask" ] ; then
      echo "$ula96"
  else
      echo "$ula96/$mask"
  fi
}






qmp_get_addr64() {

  local prefix=$1
  local node=$2
  local suffix=$3
  local mask=$4

  local addr64=$( qmp_calculate_addr64 $prefix $node $suffix )

  echo "$addr64/$mask"
}





qmp_configure_prepare() {

  local conf=$1

  echo "configuring /etc/config/$conf"

  if ! [ -f /etc/config/$conf.orig ]; then
    echo "saving original config in: /etc/config/$conf.orig"
    cp /etc/config/$conf /etc/config/$conf.orig
  fi

  uci revert $conf
  echo "" > /etc/config/$conf

}




qmp_configure_network() {

  local conf="network"

  qmp_configure_prepare $conf

  if qmp_uci_test qmp.interfaces.configure_switch ; then

    local switch_device="$(uci get qmp.interfaces.configure_switch)"

    uci set $conf.$switch_device="switch"
    uci set $conf.$switch_device.enable="1"
    uci set $conf.$switch_device.enable_vlan="1"
    uci set $conf.$switch_device.reset="1"

    uci set $conf.lan_ports="switch_vlan"
    uci set $conf.lan_ports.vlan="1"
    uci set $conf.lan_ports.device="$switch_device"
    uci set $conf.lan_ports.ports="0 1 5t"

    uci set $conf.wan_ports="switch_vlan"
    uci set $conf.wan_ports.vlan="2"
    uci set $conf.wan_ports.device="$switch_device"
    uci set $conf.wan_ports.ports="4 5t"



    if qmp_uci_test qmp.interfaces.mesh_devices && qmp_uci_test qmp.networks.mesh_protocol_vids && qmp_uci_test qmp.networks.mesh_vid_offset; then

       for protocol_vid in $(uci get qmp.networks.mesh_protocol_vids); do

         local vid_suffix="$(echo $protocol_vid | awk -F':' '{print $2}')"
         local vid_offset="$(uci get qmp.networks.mesh_vid_offset)"
         local vid="$(( $vid_offset + $vid_suffix ))"

         local mesh_ports="mesh_ports_vid${vid}"

	  uci set $conf.$mesh_ports="switch_vlan"
	  uci set $conf.$mesh_ports.vlan="$vid"
	  uci set $conf.$mesh_ports.device="$switch_device"
	  uci set $conf.$mesh_ports.ports="2t 3t 5t"

       done
    fi


  fi

  uci set $conf.loopback="interface"
  uci set $conf.loopback.ifname="lo"
  uci set $conf.loopback.proto="static"
  uci set $conf.loopback.ipaddr="127.0.0.1"
  uci set $conf.loopback.netmask="255.0.0.0"

  wan_offset=0
  for i in $(qmp_get_devices wan) ; do
    uci set $conf.wan${wan_offset}="interface"
    qmp_attach_device_to_interface $i $conf wan${wan_offset}
    uci set $conf.wan${wan_offset}.proto="dhcp"
    let wan_offset=${wan_offset}+1
  done


  local primary_mesh_device="$(qmp_get_primary_device)"
  local community_node_id
  local LSB_PRIM_MAC="$(qmp_get_mac_for_dev $primary_mesh_device | awk -F':' '{print $6}' )"

  if qmp_uci_test qmp.node.community_node_id; then
    community_node_id="$(uci get qmp.node.community_node_id)"
  elif ! [ -z "$primary_mesh_device" ] ; then
    community_node_id=$LSB_PRIM_MAC
  fi

  if qmp_uci_test qmp.interfaces.lan_devices ; then

    # If it is enabled, apply the non-overlapping DHCP-range preset policy

	LAN_MASK="$(uci get qmp.networks.lan_netmask)"
	LAN_ADDR="$(uci get qmp.networks.lan_address)"
	START=2
	LIMIT=253

    if [ $(uci get qmp.non_overlapping.ignore) -eq 0 ]; then
	LAN_MASK="255.255.0.0"
	# Last byte of lan adress must be "1" to avoid overlappings
	LAN_ADDR=$(echo $LAN_ADDR | sed -e 's/\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)/&.1:/1' | awk -F ":" '{print $1}')

	OFFSET=0
	NUM_GRP=256

	UCI_OFFSET="$(uci get qmp.non_overlapping.dhcp_offset)"

	[ $UCI_OFFSET -lt $NUM_GRP ] && OFFSET=$UCI_OFFSET

	START=$(( $(printf %d 0x$community_node_id) * $NUM_GRP + $OFFSET ))
	LIMIT=$(( $NUM_GRP - $OFFSET ))

	uci set dhcp.lan.leasetime="$(uci get qmp.non_overlapping.qmp_leasetime)"
    fi

    uci set dhcp.lan.start=$START
    uci set dhcp.lan.limit=$LIMIT
    uci commit dhcp

    uci set $conf.lan="interface"
    local device
    for device in $(qmp_get_devices lan) ; do
      qmp_attach_device_to_interface $device $conf lan
    done
    uci set $conf.lan.type="bridge"
    uci set $conf.lan.proto="static"
    uci set $conf.lan.ipaddr=$LAN_ADDR
    uci set $conf.lan.netmask=$LAN_MASK
    uci set $conf.lan.dns="$(uci get qmp.networks.dns)"

  fi

  # MESH DEVICES CONFIGURATION
  local counter=1

  if uci get qmp.interfaces.mesh_devices && uci get qmp.networks.mesh_protocol_vids && uci get qmp.networks.mesh_vid_offset; then
    for dev in $(qmp_get_devices mesh); do

        # If dev is empty, nothing to do
        [ -z "$dev" ] && continue

        # Let's configure the mesh device
	echo "Configuring "$dev" for Meshing"

	# Check if the current device is configured as no-vlan
	local use_vlan=1
	for no_vlan_int in $(uci get qmp.interfaces.no_vlan_devices); do
		[ "$no_vlan_int" == "$dev" ] && use_vlan=0
	done
	
	for protocol_vid in $(uci get qmp.networks.mesh_protocol_vids); do

         local protocol_name="$(echo $protocol_vid | awk -F':' '{print $1}')"
         local vid_suffix="$(echo $protocol_vid | awk -F':' '{print $2}')"
         local vid_offset="$(uci get qmp.networks.mesh_vid_offset)"
         local vid="$(( $vid_offset + $vid_suffix ))"

         local mesh="mesh_${protocol_name}_${counter}"
         local ip6_suffix="2002::${counter}${vid_suffix}" #put typical IPv6 prefix (2002::), otherwise ipv6 calc assumes mapped or embedded ipv4 address
	
	 # Since all interfaces are defined somewhere (LAN, WAN or with Rescue IP), 
	 # in case of not use vlan tag, device definition is not needed.
	 # However for the moment only bmx6 support not-vlan interfaces
	 if [ "$protocol_name" != "bmx6" ] || [ $use_vlan -eq 1 ]; then
             uci set $conf.$mesh="interface"
             uci set $conf.$mesh.ifname="$dev.$vid"
             uci set $conf.$mesh.proto="static"
         fi

	 # Configure IPv6 address only if mesh_prefix48 is defined (bmx6 does not need it)
	 if qmp_uci_test qmp.networks.${protocol_name}_mesh_prefix48; then
             uci set $conf.$mesh.ip6addr="$(qmp_get_ula96 $(uci get qmp.networks.${protocol_name}_mesh_prefix48):: $primary_mesh_device $ip6_suffix 128)"
	 fi

         done
      # Configuring rescue IPs only if the device is not LAN nor WAN
       [ "$dev" != "br-lan" ] && {
		isWan=0
		for w in $(qmp_get_devices wan); do [ "$w" == "$dev" ] && isWan=1; done
		[ $isWan -eq 0 ] && qmp_configure_rescue_ip $dev
	}

       counter=$(( $counter + 1 ))
    done
  fi

  uci commit $conf
#  /etc/init.d/$conf restart
}



qmp_configure_bmx6() {
#  set -x
  local conf="bmx6"

  qmp_configure_prepare $conf

  uci set $conf.general="bmx6"
#  uci set $conf.general.globalPrefix="$(uci get qmp.networks.bmx6_mesh_prefix48)::/48"
#  uci set $conf.general.udpDataSize=1000

  uci set $conf.bmx6_config_plugin=plugin
  uci set $conf.bmx6_config_plugin.plugin=bmx6_config.so

  uci set $conf.bmx6_json_plugin=plugin
  uci set $conf.bmx6_json_plugin.plugin=bmx6_json.so

  uci set $conf.bmx6_sms_plugin=plugin
  uci set $conf.bmx6_sms_plugin.plugin=bmx6_sms.so

  # chat file must be syncronized using sms
  cfg_sms=$(uci add $conf syncSms)
  uci set $conf.${cfg_sms}.syncSms=chat

  uci set $conf.ipVersion=ipVersion
  uci set $conf.ipVersion.ipVersion="6"
  if value="$(uci get qmp.networks.bmx6_throwRules)" ; then
    uci set $conf.ipVersion.throwRules="$value"
  fi
  if value="$(uci get qmp.networks.bmx6_tablePrefTuns)"; then
    uci set $conf.ipVersion.tablePrefTuns="$value"
  fi
  if value=$(uci get qmp.networks.bmx6_tableTuns); then
    uci set $conf.ipVersion.tableTuns="$value"
  fi


  local primary_mesh_device="$(qmp_get_primary_device)"

  local community_node_id
  if qmp_uci_test qmp.node.community_node_id; then
    community_node_id="$(uci get qmp.node.community_node_id)"
  elif ! [ -z "$primary_mesh_device" ] ; then
    community_node_id="$( qmp_get_mac_for_dev $primary_mesh_device | awk -F':' '{print $6}' )"
  fi

  if qmp_uci_test qmp.interfaces.mesh_devices && qmp_uci_test qmp.networks.mesh_protocol_vids && qmp_uci_test qmp.networks.mesh_vid_offset; then

    local counter=1

    for dev in $(qmp_get_devices mesh); do
       for protocol_vid in $(uci get qmp.networks.mesh_protocol_vids); do

         local protocol_name="$(echo $protocol_vid | awk -F':' '{print $1}')"
	
         if [ "$protocol_name" = "bmx6" ] ; then
	    
	    # Check if the current device is configured as no-vlan
	    local use_vlan=1
	    for no_vlan_int in $(uci get qmp.interfaces.no_vlan_devices); do
		[ "$no_vlan_int" == "$dev" ] && use_vlan=0
	    done
		
	    if [ $use_vlan -eq 1 ]; then
	        # If vlan tagging
                local vid_suffix="$(echo $protocol_vid | awk -F':' '{print $2}')"
                local vid_offset="$(uci get qmp.networks.mesh_vid_offset)"
	        local ifname="$dev.$(( $vid_offset + $vid_suffix ))"
	    else
	        # If not vlan tagging
		local ifname="$dev"
	    fi

	    uci set $conf.mesh_$counter="dev"
	    uci set $conf.mesh_$counter.dev="$ifname"

	    if qmp_uci_test qmp.networks.bmx6_ipv4_address ; then
	      local bmx6_ipv4_netmask="$(echo $(uci get qmp.networks.bmx6_ipv4_address) | cut -s -d / -f2)"
	      local bmx6_ipv4_address="$(echo $(uci get qmp.networks.bmx6_ipv4_address) | cut -d / -f1)"
	      [ -z "$bmx6_ipv4_netmask" ] && bmx6_ipv4_netmask="32"
	      uci set $conf.general.tun4Address="$bmx6_ipv4_address/$bmx6_ipv4_netmask"

	    elif qmp_uci_test qmp.networks.bmx6_ipv4_prefix24 ; then
	      local ipv4_suffix24="$(( 0x$community_node_id / 0x100 )).$(( 0x$community_node_id % 0x100 ))"
	      uci set $conf.general.tun4Address="$(uci get qmp.networks.bmx6_ipv4_prefix24).$ipv4_suffix24/32"
	    fi

	    counter=$(( $counter + 1 ))
         fi

       done
    done
  fi


  if qmp_uci_test qmp.networks.bmx6_ripe_prefix48 ; then
    uci set $conf.general.tun6Address="$(uci get qmp.networks.bmx6_ripe_prefix48):$community_node_id:0:0:0:1/64"
  fi


  if qmp_uci_test qmp.tunnels.search_ipv6_tunnel ; then
    uci set $conf.tun6Out="tunOut"
    uci set $conf.tun6Out.tunOut="tun6Out"
    uci set $conf.tun6Out.network="$(uci get qmp.tunnels.search_ipv6_tunnel)"
    uci set $conf.tun6Out.mtu=1360
  fi

  if qmp_uci_test qmp.tunnels.search_ipv4_tunnel ; then
    uci set $conf.tun4Out="tunOut"
    uci set $conf.tun4Out.tunOut="tun4Out"
    uci set $conf.tun4Out.network="$(uci get qmp.tunnels.search_ipv4_tunnel)"
    uci set $conf.tun4Out.mtu=1360

  elif qmp_uci_test qmp.tunnels.offer_ipv4_tunnel ; then
    uci set $conf.tunInRemote="tunInRemote"
    uci set $conf.tunInRemote.tunInRemote="$(qmp_get_ula96 $(uci get qmp.networks.bmx6_mesh_prefix48):: $primary_mesh_device 2002::ffff )"

    uci set $conf.tun4InNet="tunInNet"
    uci set $conf.tun4InNet.tunInNet="$(uci get qmp.tunnels.offer_ipv4_tunnel)"
    uci set $conf.tun4InNet.bandwidth="1000000"
  fi

  #Configuring the tunnel to search 10/8 networks
  uci set $conf.nodes10="tunOut"
  uci set $conf.nodes10.tunOut="nodes10"
  uci set $conf.nodes10.network="10.0.0.0/8"
  uci set $conf.nodes10.mtu=1360

  uci commit $conf
#  /etc/init.d/$conf restart
}

qmp_configure_olsr6() {

  local conf="olsrd"
  local file="/etc/olsrd.conf"

  qmp_configure_prepare $conf

  uci add $conf "olsrd"
  uci set $conf.@olsrd[0].config_file="/etc/olsrd.conf"

  uci commit $conf

cat <<EOF > $file
DebugLevel 1
IpVersion  6
#RtTable        90
#RtTableDefault 91
#LinkQualityFishEye  0

LoadPlugin "olsrd_txtinfo.so.0.1"
{
  PlParam     "Accept"   "0::0"
}

EOF

  local primary_mesh_device="$(qmp_get_primary_device)"
  
  local community_node_id
  if qmp_uci_test qmp.node.community_node_id; then
    community_node_id="$(uci get qmp.node.community_node_id)"
  elif ! [ -z "$primary_mesh_device" ] ; then
    community_node_id="$( qmp_get_mac_for_dev $primary_mesh_device | awk -F':' '{print $6}' )"
  fi


  if qmp_uci_test qmp.interfaces.mesh_devices && qmp_uci_test qmp.networks.mesh_protocol_vids && qmp_uci_test qmp.networks.mesh_vid_offset; then

    local counter=1

    for dev in $(qmp_get_devices mesh); do
       for protocol_vid in $(uci get qmp.networks.mesh_protocol_vids); do

         local protocol_name="$(echo $protocol_vid | awk -F':' '{print $1}')"

         if [ "$protocol_name" = "olsr6" ] ; then

           local vid_suffix="$(echo $protocol_vid | awk -F':' '{print $2}')"
           local vid_offset="$(uci get qmp.networks.mesh_vid_offset)"
	   local ifname="$dev.$(( $vid_offset + $vid_suffix ))"
           local mode="$(if echo $dev | grep -v ath | grep -v wlan > /dev/null 2>&1; then echo ether; else echo mesh; fi)"
           local mesh="mesh_${protocol_name}_${counter}"
           local ip6_suffix="2002::${counter}${vid_suffix}" #put typical IPv6 prefix (2002::), otherwise ipv6 calc assumes mapped or embedded ipv4 address
           local ip6_addr="$( qmp_get_ip6_fast $(qmp_get_ula96 $(uci get qmp.networks.${protocol_name}_mesh_prefix48):: $primary_mesh_device $ip6_suffix 128) )"

cat <<EOF >> $file

Interface "$ifname"
{
    Mode                "$mode"
    IPv6Multicast       FF0E::1
    IPv6Src             $ip6_addr
}

EOF
	    counter=$(( $counter + 1 ))
         fi
       done
    done
  fi



  if qmp_uci_test qmp.networks.olsr6_ripe_prefix48 ; then
cat <<EOF >> $file
Hna6
{
$(uci get qmp.networks.olsr6_ripe_prefix48):$community_node_id:0:0:0:0 64
}

EOF
  fi

  if qmp_uci_test qmp.networks.niit_prefix96 ; then

    if qmp_uci_test qmp.networks.olsr6_ipv4_address && qmp_uci_test qmp.networks.olsr6_ipv4_netmask && qmp_uci_test qmp.networks.olsr6_6to4_netmask; then
cat <<EOF >> $file
Hna6
{
$( qmp_get_ip6_slow $(uci get qmp.networks.niit_prefix96):$(uci get qmp.networks.olsr6_ipv4_address)/$(uci get qmp.networks.olsr6_6to4_netmask)) $(uci get qmp.networks.olsr6_6to4_netmask)
}

EOF

    elif qmp_uci_test qmp.networks.olsr6_ipv4_prefix24; then
      local prefix24=$(uci get qmp.networks.olsr6_ipv4_prefix24)
cat <<EOF >> $file
Hna6
{
$( qmp_get_ip6_slow $(uci get qmp.networks.niit_prefix96):$(uci get qmp.networks.olsr6_ipv4_prefix24).$(( 0x$community_node_id / 0x100 )).$(( 0x$community_node_id % 0x100 ))/128 ) 128
}

EOF
    fi
  fi
#  /etc/init.d/$conf restart
}


qmp_set_hosts() {
  echo "Configuring /etc/hosts file with qmpadmin entry"

  local ip=$(uci get bmx6.general.tun4Address | cut -d'/' -f1)
  local hn=$(uci get system.@system[0].hostname)

  if [ -z "$ip" -o -z "$hn" ]; then
 	echo "Cannot get IP or HostName"
	return
  fi

  if [ $(cat /etc/hosts | grep qmpadmin | grep "^$ip" -c) -eq 0 ]; then
        cat /etc/hosts | grep -v qmpadmin > /tmp/hosts.tmp
        echo "$ip $hn admin.qmp qmpadmin" >> /tmp/hosts.tmp
        cp /tmp/hosts.tmp /etc/hosts
  fi

  echo "done"
}

qmp_configure_system() {

  local primary_mesh_device="$(qmp_get_primary_device)"

  local community_node_id
  if qmp_uci_test qmp.node.community_node_id; then
    community_node_id="$(uci get qmp.node.community_node_id)"
  else
    community_node_id="$(qmp_get_mac_for_dev $primary_mesh_device | awk -F':' '{print $6}' )"
  fi

  local community_id="$(uci get qmp.node.community_id)"
  [ -z "$community_id" ] && community_id="qmp"

  # set hostname
  uci set system.@system[0].hostname=${community_id}${community_node_id}
  uci commit system
  echo "${community_id}${community_node_id}" > /proc/sys/kernel/hostname

  # enable IPv6 in httpd:
  uci set uhttpd.main.listen_http="80"
  uci set uhttpd.main.listen_https="443"
  uci commit uhttpd
  /etc/init.d/uhttpd restart

  # configuring hosts
  qmp_set_hosts
}


qmp_check_force_internet() {
	[ "$(uci get qmp.networks.force_internet)" == "1" ] && qmp_gw_offer_default
	[ "$(uci get qmp.networks.force_internet)" == "0" ] && qmp_gw_search_default
}

qmp_configure() {
  qmp_check_force_internet
  qmp_configure_network
  qmp_configure_bmx6
  qmp_configure_olsr6
  qmp_configure_system

}

