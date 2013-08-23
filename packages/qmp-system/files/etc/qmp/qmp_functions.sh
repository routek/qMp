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
#	Axel Neumann
#   Pau Escrich <p4u@dabax.net>
#	Simó Albert i Beltran
#

QMP_PATH="/etc/qmp"
SOURCE_FUNCTIONS=1

#######################
# Importing files
######################
if [ -z "$SOURCE_OPENWRT_FUNCTIONS" ]
then
	. /lib/functions.sh
	SOURCE_OPENWRT_FUNCTIONS=1
fi
. $QMP_PATH/qmp_common.sh
[ -z "$SOURCE_GW" ] && . $QMP_PATH/qmp_gw.sh
[ -z "$SOURCE_NET" ] && . $QMP_PATH/qmp_network.sh

# requires ip ipv6calc awk sed grep

qmp_get_llocal_for_dev() {
  local dev=$1
  ip a show dev $dev | awk '/inet6/{print $2}'
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

qmp_check_device() {
	ip link show $1 1> /dev/null 2>/dev/null
	return $?
}

qmp_set_vlan() {
  local viface="$1" # lan/wan/meshX
  local vid=$2 # 11/12
  [ -z "$viface" ] || [ -z "$vid" ] && return

  uci set network.${viface}_$vid=interface
  uci set network.${viface}_$vid.proto=none
  uci set network.${viface}_$vid.ifname=@$viface.$vid
  uci commit network
}

qmp_get_virtual_iface() {
  local device="$1"
  local viface=""

  if qmp_is_routerstationpro; then
    if [ "$device" == "eth1" ]; then
      echo "rsp_e1"
      return
    fi
    if [ "$device" == "eth1.1" ]; then
      echo "rsp_e1_1"
      return
    fi
  fi

   # is lan?
  if [ "$device" == "br-lan" ]; then
    viface="lan"
    echo $viface
    return
  fi

  for l in $(qmp_get_devices lan); do 
    if [ "$l" == "$device" ]; then 
      viface="lan"
      echo $viface
      return
    fi
  done

  [ -n "$viface" ] && { echo $viface; return; }

  # id is the first and char and the numbers of the device [e]th[0] [w]lan[1]
  local id_num=$(echo $device | tr -d "[A-z]" | tr - _ | tr . _)
  local id_char=$(echo $device | cut -c 1)

  # is wan
  for w in $(qmp_get_devices wan); do 
   if [ "$w" == "$device" ]; then
     viface="wan_${id_char}${id_num}"
     echo $viface
     return
   fi
  done

  # is mesh
  for w in $(qmp_get_devices mesh); do 
   if [ "$w" == "$device" ]; then
     viface="mesh_${id_char}${id_num}"
     break
   fi
  done
  
  echo "$viface" 
}

# arg1=<mesh|lan|wan>, returns the devices which have to be configured in such mode
qmp_get_devices() {
  local devices=""

  if [ "$1" == "mesh" ]; then 
    local brlan_enabled=0
    for dev in $(uci get qmp.interfaces.mesh_devices 2>/dev/null); do

        # Lookging if device is defined as LAN, in such case dev=br-lan, but only once
        # except eth1 for RouterStation Pro
        if ! ( [[ "$dev" == "eth1" ]] && qmp_is_routerstationpro ) ; then
            for landev in $(uci get qmp.interfaces.lan_devices 2>/dev/null); do
                if [ "$landev" == "$dev" ]; then
                    if [ $brlan_enabled -eq 0 ]; then
                        dev="br-lan"
                        brlan_enabled=1
                    else
                        dev=""
                    fi
                    break
                fi
            done
        fi

      [ -n "$dev" ] && devices="$devices $dev"
    done
  fi

  if [ "$1" == "lan" ]; then
     devices="$(uci get qmp.interfaces.lan_devices 2>/dev/null)"
  fi

  if [ "$1" == "wan" ]; then
     devices="$(uci get qmp.interfaces.wan_devices 2>/dev/null)"
  fi

  if qmp_is_routerstationpro && [ "$1" == "wan" -o "$1" == "lan" ]; then
     devices="$(echo $devices | sed -e "s/\beth1\b/eth1.1/g")"
  fi

  echo "$devices"
}

qmp_get_rescue_ip() {
	local device=$1
	local mac=""
	[ -z "$device" ] && return 1

	local rprefix=$(qmp_uci_get networks.rescue_prefix24 2>/dev/null)
	rprefix=${rprefix:-169.254}
	
	# if device is virtual, get the ifname
	if qmp_uci_test network.$device.ifname; then
	  local devvirt="$(qmp_uci_get_raw network.$device.ifname | tr -d @)"
	  device=${devvirt:-$device}
	fi

	# is it a wireless device?
	if qmp_uci_test wireless.$device.device; then
		local radio="$(qmp_uci_get_raw wireless.$device.device)"
		mac=$(qmp_uci_get_raw wireless.$radio.macaddr)
	else
		mac=$(ip addr show dev $device 2>/dev/null| grep -m 1 "link/ether" | awk '{print $2}')
	fi

	mac=${mac:-FF:FF:FF:FF:FF:FF}
		
	#local xoctet=$(printf "%d\n" 0x$(echo $mac | cut -d: -f5))
	local yoctet=$(printf "%d\n" 0x$(echo $mac | cut -d: -f6))
	local rip="$rprefix.$yoctet.1"

	echo "$rip"
}

# Scan and configure the network devices (lan, mesh and wan)
# if $1 is set to "force", it rescan all devices 
qmp_configure_smart_network() {
	echo "---------------------------------------"
	echo "Starting smart networking configuration"
	echo "---------------------------------------"
	local force=$1
	local mesh=""
	local wan=""
	local lan=""
	local dev=""
	local phydevs=""
	local ignore_devs=""
	
	[ "$force" != "force" ] && {
		ignore_devs="$(qmp_uci_get interfaces.ignore_devices)"
	}

	for dev in $(ls /sys/class/net/); do
		[ -e /sys/class/net/$dev/device ] || [ dev == "eth0" ] && {
			local id 
			local ignore=0
			
			# Check if device is in the ignore list
				for id in $ignore_devs; do
					[ "$id" == "$dev" ] && ignore=1
				done

			[ $ignore -eq 0 ] && phydevs="$phydevs $dev\n"
		}
	done

	phydevs="$(echo -e "$phydevs" | grep -v -e ".*ap$" | grep -v "\\." | sort -u | tr -d ' ' \t)"
	
	# if force is not enabled, we are not changing the existing lan/wan/mesh (only adding new ones)
	[ "$force" != "force" ] && {
		lan="$(qmp_uci_get interfaces.lan_devices)"
		wan="$(qmp_uci_get interfaces.wan_devices)"
		mesh="$(qmp_uci_get interfaces.mesh_devices)"
	}

	local j=0
	local mode=""
	local cnt
	local cdev

	for dev in $phydevs; do
		# If force is enabled, do not check if the device is already configured		
		[ "$force" != "force" ] && {
			cnt=0
			# If it is already configured, doing nothing
			for cdev in $lan; do
				[ "$cdev" == "$dev" ] && cnt=1
			done
			for cdev in $mesh; do
				[ "$cdev" == "$dev" ] && cnt=1
			done
			for cdev in $wan; do
				[ "$cdev" == "$dev" ] && cnt=1
			done
			[ $cnt -eq 1 ] && continue
		}
		
		# If not found before...
		[ "$dev" == "eth0" ] && {
			lan="$lan eth0"
			mesh="$mesh eth0"
			continue
		}

		## if there is not yet a LAN device, configuring as lan and mesh
		##[ -z "$lan" ] && { lan="$dev"; mesh="$dev" && continue

		# if it is a wifi device
		[ -e "/sys/class/net/$dev/phy80211" ] && {
			j=0
			while qmp_uci_test qmp.@wireless[$j]; do
				[ "$(qmp_uci_get @wireless[$j].device)" == "$dev" ] && {
					mode="$(qmp_uci_get @wireless[$j].mode)"
					[ "$mode" == "ap" ] && lan="$dev $lan" || mesh="$dev $mesh"
					break
				}
				j=$(($j+1))
			done
		} && continue

		# if there is already LAN device and it is not wifi, use as WAN
		[ -z "$wan" ] && wan="$dev" && continue
		
		# else use as LAN and MESH
		lan="$dev $lan"
		mesh="$dev $mesh"
	done
	
	echo "Network devices found:"
	echo "- LAN $lan"
	echo "- MESH $mesh"
	echo "- WAN $wan"

	# Writes the devices to the config
	qmp_uci_set interfaces.lan_devices "$(echo $lan | sed -e s/"^ "//g -e s/" $"//g)"
	qmp_uci_set interfaces.mesh_devices "$(echo $mesh | sed -e s/"^ "//g -e s/" $"//g)"
	qmp_uci_set interfaces.wan_devices "$(echo $wan | sed -e s/"^ "//g -e s/" $"//g)"
	qmp_uci_set interfaces.ignore_devices "$ignore_devs"
}

qmp_attach_device_to_interface() {
	local device=$1
	local interface=$2
	local intype="$(qmp_uci_get_raw network.$interface.type)" 
	
	echo "Attaching device $device to interface $interface"

	# is it a wifi device?
	if qmp_uci_test wireless.$device; then
		qmp_uci_set_raw wireless.$device.network=$interface
		echo " -> $device wireless attached to $interface"

	# if it is not
	else
			if [ "$intype" == "bridge" ]; then
				qmp_uci_add_list_raw network.$interface.ifname=$device
				echo " -> $device attached to $interface bridge"
			else
				qmp_uci_set_raw network.$interface.ifname=$device
				echo " -> $device attached to $interface"
			fi
	fi
}

qmp_configure_rescue_ip() {
	local device=$1
		
	[ -z "$device" ] && return 1
	
	local rip="$(qmp_get_rescue_ip $device)"
	[ -z "$rip" ] && { echo "Cannot get rescue IP for device $device"; return 1; }

	local viface="${2:-$(qmp_get_virtual_iface $device)}"
	
	echo "Rescue IP for device $device/$viface is $rip"	

	local conf="network"
	
	uci set $conf.${viface}="interface"
	#qmp_attach_viface_to_interface $viface $conf ${viface}
	uci set $conf.${viface}.proto="static"
	uci set $conf.${viface}.ipaddr="$rip"
	uci set $conf.${viface}.netmask="255.255.255.248"
	uci commit $conf
}

qmp_is_routerstationpro() {
	cat /proc/cpuinfo | grep -q "^machine[[:space:]]*: Ubiquiti RouterStation Pro$"
}

qmp_configure_routerstationpro_switch() {
	local vids="$@"

	uci set network.eth1="switch"
	uci set network.eth1.enable="1"
	uci set network.eth1.enable_vlan="1"
	uci set network.eth1.reset="1"

	uci set network.mesh_ports_vid1="switch_vlan"
	uci set network.mesh_ports_vid1.vlan="1"
	uci set network.mesh_ports_vid1.vid="1"
	uci set network.mesh_ports_vid1.device="eth1"
	uci set network.mesh_ports_vid1.ports="0t 4"
      
	for vid in $vids
	do
		uci set network.mesh_ports_vid$vid="switch_vlan"
		uci set network.mesh_ports_vid$vid.vlan="$vid"
		uci set network.mesh_ports_vid$vid.vid="$vid"
		uci set network.mesh_ports_vid$vid.device="eth1"
		uci set network.mesh_ports_vid$vid.ports="0t 2t 3t"
	done

	local viface="$(qmp_get_virtual_iface eth1)"
	uci set network.$viface="interface"
	uci set network.$viface.proto="static"
	uci set network.$viface.ifname="eth1"
	uci commit network
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

  local addr_long=$( ipv6calc -q  --in ipv6 $addr --showinfo -m 2>&1 | awk -F'=' '/IPV6=/{print $2}' )

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

qmp_configure_rescue_ip_device()
{
	local dev="$1"
	local conf="$2"
	local viface="$3"

	# Configuring rescue IPs
	if [ "$dev" == "eth1" ] && qmp_is_routerstationpro
	then
		if qmp_is_in "eth1.1" $(qmp_get_devices lan)
		then
			return
		fi
		qmp_configure_rescue_ip eth1 ${viface}_1_rescue
		qmp_attach_device_to_interface @$viface.1 ${viface}_1_rescue
	elif qmp_is_in "$dev" $(qmp_get_devices wan) || [ "$dev" == "br-lan" ]
	then
		# If it is WAN or LAN
		qmp_configure_rescue_ip $dev ${viface}_rescue
		qmp_attach_device_to_interface $dev ${viface}_rescue
	elif qmp_is_in "$dev" $(qmp_get_devices mesh) && [ "$dev" != "br-lan" ]
	then
		# If it is only mesh device
		qmp_configure_rescue_ip $dev 
		qmp_attach_device_to_interface $dev $viface
	fi
}

qmp_configure_prepare() {
  local conf=$1
   if ! [ -f /etc/config/$conf.orig ]; then
    echo "saving original config in: /etc/config/$conf.orig"
    cp /etc/config/$conf /etc/config/$conf.orig
  fi

  uci revert $conf
  echo "" > /etc/config/$conf
}

qmp_configure_network() {

  local conf="network"

  echo "-----------------------"
  echo "Configuring networking"
  echo "-----------------------"

  qmp_configure_prepare_network $conf

  if qmp_uci_test qmp.interfaces.mesh_devices && qmp_uci_test qmp.networks.mesh_protocol_vids && qmp_uci_test qmp.networks.mesh_vid_offset; then
    local vids="$(qmp_uci_get networks.mesh_protocol_vids | awk -F':' -v RS=" " '{print $2 + '$(uci -q get qmp.networks.mesh_vid_offset)'}')"
  fi

  if [[ -n "$vids" ]] && qmp_is_routerstationpro ; then
    
    qmp_configure_routerstationpro_switch "$vids"

  elif qmp_uci_test qmp.interfaces.configure_switch ; then

    local switch_device="$(qmp_uci_get interfaces.configure_switch)"

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

    if [[ -n "$vids" ]] ; then

       for vid in $vids; do

         local mesh_ports="mesh_ports_vid${vid}"

	  uci set $conf.$mesh_ports="switch_vlan"
	  uci set $conf.$mesh_ports.vlan="$vid"
	  uci set $conf.$mesh_ports.device="$switch_device"
	  uci set $conf.$mesh_ports.ports="2t 3t 5t"

       done
    fi

  fi
  
  # LoopBack device
  uci set $conf.loopback="interface"
  uci set $conf.loopback.ifname="lo"
  uci set $conf.loopback.proto="static"
  uci set $conf.loopback.ipaddr="127.0.0.1"
  uci set $conf.loopback.netmask="255.0.0.0"

  # WAN devices
  for i in $(qmp_get_devices wan) ; do
	echo "Configuring $i in WAN mode"
    local viface="$(qmp_get_virtual_iface $i)"
    qmp_uci_set_raw network.$viface="interface"
    qmp_attach_device_to_interface $i $viface
    qmp_uci_set_raw network.$viface.proto="dhcp"
    metric="$(qmp_uci_get network.wan_metric)"
    qmp_uci_set_raw network.$viface.metric="${metric:-2048}"
  done
  
  # Set some important variables
  local primary_mesh_device="$(qmp_get_primary_device)"
  local lsb_prim_mac="$(qmp_get_mac_for_dev $primary_mesh_device | awk -F':' '{print $6}' )"
  local community_node_id="$(qmp_uci_get node.community_node_id)"
  local dns="$(qmp_uci_get networks.dns)"
  local lan_mask="$(qmp_uci_get networks.lan_netmask)"
  local lan_addr="$(qmp_uci_get networks.lan_address)"

  lsb_prim_mac=${lsb_prim_mac:-0}
  primary_mesh_device=${primary_mesh_device:-eth0}
  community_node_id=${community_node_id:-$lsb_prim_mac}
  lan_addr=${lan_addr:-172.30.22.1}
  lan_mask=${lan_mask:-255.255.255.0}

  # If DHCP non overlapping (layer3 roaming) enabled
  # last byte of lan adress must be "1" to avoid overlappings
  # mask must be /16
  if [ $(qmp_uci_get non_overlapping.ignore) -eq 0 ]; then
     lan_mask="255.255.0.0"
     lan_addr=$(echo $lan_addr | sed -e 's/\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)\.[0-9]\{1,3\}/\1.1/1')
  fi
  
  # Configure DHCP
  qmp_configure_dhcp $community_node_id

  # LAN device (br-lan) configuration
  echo "Configuring LAN bridge"
  qmp_uci_set_raw network.lan="interface"
  qmp_uci_set_raw network.lan.type="bridge"
  qmp_uci_set_raw network.lan.auto='1'
  qmp_uci_set_raw network.lan.proto="static"
  qmp_uci_set_raw network.lan.ipaddr="$lan_addr"
  qmp_uci_set_raw network.lan.netmask="$lan_mask"
  [ -n "$dns" ] && qmp_uci_set_raw network.lan.dns="$dns"

  # Attaching LAN devices to br-lan
  local device
  for device in $(qmp_get_devices lan) ; do
    qmp_attach_device_to_interface $device lan
  done

  # MESH devices configuration
  local counter=1

  if qmp_uci_test qmp.interfaces.mesh_devices && 
	 qmp_uci_test qmp.networks.mesh_protocol_vids && 
	 qmp_uci_test qmp.networks.mesh_vid_offset; then

     for dev in $(qmp_get_devices mesh); do
       # If dev is empty, nothing to do
       [ -z "$dev" ] && continue

        # Let's configure the mesh device
	   echo "Configuring "$dev" for Meshing"

	    # Check if the current device is configured as no-vlan
	    local use_vlan=1
	    for no_vlan_int in $(qmp_uci_get interfaces.no_vlan_devices 2>/dev/null); do
	      [ "$no_vlan_int" == "$dev" ] && use_vlan=0
	    done

        local protocol_vids="$(qmp_uci_get qmp.networks.mesh_protocol_vids 2>/dev/null)"
        [ -z "$protocol_vids" ] && protocol_vids="olsr6:1 bmx6:2"

	  for protocol_vid in $protocol_vids; do

	     # Calculating the VID offset for VLAN tag
         local protocol_name="$(echo $protocol_vid | awk -F':' '{print $1}')"
         local vid_suffix="$(echo $protocol_vid | awk -F':' '{print $2}')"
         local vid_offset="$(qmp_uci_get networks.mesh_vid_offset)"
         local vid="$(( $vid_offset + $vid_suffix ))"
        
	     # virtual interface
         local viface=$(qmp_get_virtual_iface $dev)

         # put typical IPv6 prefix (2002::), otherwise ipv6 calc assumes mapped or embedded ipv4 address
         local ip6_suffix="2002::${counter}${vid_suffix}" 
	
	     # Since all interfaces are defined somewhere (LAN, WAN or with Rescue IP), 
	     # in case of not use vlan tag, device definition is not needed.
	     # However for the moment only bmx6 support not-vlan interfaces
	     if [ "$protocol_name" != "bmx6" ] || [ $use_vlan -eq 1 ]; then
           qmp_set_vlan $viface $vid
         fi
         
	     # Configure IPv6 address only if mesh_prefix48 is defined (bmx6 does not need it)
	     if qmp_uci_test qmp.networks.${protocol_name}_mesh_prefix48; then
           local ip6="$(qmp_get_ula96 $(uci get qmp.networks.${protocol_name}_mesh_prefix48):: $primary_mesh_device $ip6_suffix 128)"
           echo "Configuring $ip6 for $protocol_name"
           qmp_uci_set_raw network.${viface}_$vid.proto=static
           qmp_uci_set_raw network.${viface}_$vid.ip6addr="$ip6"
         else
           qmp_uci_set_raw network.${viface}_$vid.proto=none
           qmp_uci_set_raw network.${viface}_$vid.auto=1
	    fi
       done

       qmp_configure_rescue_ip_device "$dev" "$conf" "$viface"
       counter=$(( $counter + 1 ))
    done
  fi

  uci commit
}


qmp_remove_qmp_bmx6_tunnels()
{	
	if echo "$1" | grep -q "^qmp_"
	then
		uci delete bmx6.$1
	fi
	uci commit bmx6
}

qmp_unconfigure_bmx6_gateways()
{
	config_load bmx6
	config_foreach qmp_remove_qmp_bmx6_tunnels tunInNet
	config_foreach qmp_remove_qmp_bmx6_tunnels tunDev
	config_foreach qmp_remove_qmp_bmx6_tunnels tunIn
	config_foreach qmp_remove_qmp_bmx6_tunnels tunOut
}


qmp_translate_configuration()
{
	orig_config=$1
	orig_section=$2
	orig_option=$3

	dest_config=$4
	dest_section=$5
	dest_option=${6:-$orig_option}

	value="$(uci -q get $orig_config.$orig_section.$orig_option)"
	if [ -n "$value" ]
	then
		uci set $dest_config.$dest_section.$dest_option="$value"
	fi
}

qmp_add_qmp_bmx6_tunnels()
{
	local section=$1
	local name="$section"
	local config=bmx6
	local ignore
	
	config_get ignore "$section" ignore
	
	[ "$ignore" = "1" ] && return
	
	[ -z "$name" ] && name="qmp_$gateway" || name="qmp_$name"
	
	qmp_log Configuring gateway $name
	
	local type
	config_get type "$section" type
	if [ "$type" = "offer" ]
	then
		
		bmx6_type=tunIn
		uci set $config.$name="$bmx6_type"
		uci set $config.$name.$bmx6_type="$section"
		qmp_translate_configuration gateways $section network $config $name $bmx6_type
		qmp_translate_configuration gateways $section network $config $name
		#qmp_translate_configuration gateways $section bandwidth $config $name
	else
		# if [ "$type" = "search" ]
		bmx6_type=tunOut
		uci set $config.$name="$bmx6_type"
		uci set $config.$name.$bmx6_type="$section"
		local t
		for t in network gwName address minPrefixLen maxPrefixLen hysteresis bonus \
			tableRule minBandwidth exportDistance
		do		
			qmp_translate_configuration gateways $section $t $config $name
		done
	fi
	
	gateway="$(($gateway + 1))"
}

qmp_configure_bmx6_gateways()
{
	qmp_unconfigure_bmx6_gateways
	config_load gateways
	gateway=0
	config_foreach qmp_add_qmp_bmx6_tunnels gateway
	uci commit bmx6
}


qmp_configure_bmx6() {
  local conf="bmx6"

  qmp_configure_prepare $conf
  uci set $conf.general="bmx6"
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

  local primary_mesh_device="$(qmp_get_primary_device)"

  local community_node_id
  if qmp_uci_test qmp.node.community_node_id; then
    community_node_id="$(qmp_uci_get node.community_node_id)"
  elif ! [ -z "$primary_mesh_device" ] ; then
    community_node_id="$( qmp_get_mac_for_dev $primary_mesh_device | awk -F':' '{print $6}' )"
  fi

  if qmp_uci_test qmp.interfaces.mesh_devices && 
  qmp_uci_test qmp.networks.mesh_protocol_vids && 
  qmp_uci_test qmp.networks.mesh_vid_offset; then

    local counter=1

    for dev in $(qmp_get_devices mesh); do
       for protocol_vid in $(uci get qmp.networks.mesh_protocol_vids); do

         local protocol_name="$(echo $protocol_vid | awk -F':' '{print $1}')"
	
         if [ "$protocol_name" = "bmx6" ] ; then
	    
	    # Check if the current device is configured as no-vlan
	    local use_vlan=1
	    for no_vlan_int in $(qmp_uci_get interfaces.no_vlan_devices); do
		[ "$no_vlan_int" == "$dev" ] && use_vlan=0
	    done
		
		# If vlan tagging
	    if [ $use_vlan -eq 1 ]; then
                local vid_suffix="$(echo $protocol_vid | awk -F':' '{print $2}')"
                local vid_offset="$(qmp_uci_get networks.mesh_vid_offset)"
				local ifname="$dev.$(( $vid_offset + $vid_suffix ))"
		# If not vlan tagging
	    else
			local ifname="$dev"
	    fi

	    uci set $conf.mesh_$counter="dev"
	    uci set $conf.mesh_$counter.dev="$ifname"

	    if qmp_uci_test qmp.networks.bmx6_ipv4_address ; then
	      local bmx6_ipv4_netmask="$(echo $(uci get qmp.networks.bmx6_ipv4_address) | cut -s -d / -f2)"
	      local bmx6_ipv4_address="$(echo $(uci get qmp.networks.bmx6_ipv4_address) | cut -d / -f1)"
	      [ -z "$bmx6_ipv4_netmask" ] && bmx6_ipv4_netmask="32"
	      uci set $conf.general.tun4Address="$bmx6_ipv4_address/$bmx6_ipv4_netmask"
	      uci set $conf.tmain=tunDev
	      uci set $conf.tmain.tunDev=tmain
	      uci set $conf.tmain.tun4Address="$bmx6_ipv4_address/$bmx6_ipv4_netmask"

	    else
	      local ipv4_suffix24="$(( 0x$community_node_id % 0x100 ))"
	      local ipv4_prefix24="$(uci get qmp.networks.bmx6_ipv4_prefix24)"
	      if [ $(echo -n "$ipv4_prefix24" | tr -d [0-9] | wc -c) -lt 2 ]; then
	      	ipv4_prefix24="${ipv4_prefix24}.0"
	      fi
	      uci set $conf.general.tun4Address="$ipv4_prefix24.$ipv4_suffix24/32"
	      uci set $conf.tmain=tunDev
	      uci set $conf.tmain.tunDev=tmain
	      uci set $conf.tmain.tun4Address="$ipv4_prefix24.$ipv4_suffix24/32"

	    fi
	    counter=$(( $counter + 1 ))
         fi

       done
    done
  fi


  if qmp_uci_test qmp.networks.bmx6_ripe_prefix48 ; then
    uci set $conf.general.tun6Address="$(uci get qmp.networks.bmx6_ripe_prefix48):$community_node_id:0:0:0:1/64"
    uci set $conf.tmain=tunDev
    uci set $conf.tmain.tunDev=tmain
    uci set $conf.tmain.tun6Address="$(qmp_uci_get networks.bmx6_ripe_prefix48):$community_node_id:0:0:0:1/64"
  fi

  qmp_configure_bmx6_gateways

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
           local mode="$(if echo $dev | grep -v "\(ath\|wlan\)" > /dev/null 2>&1; then echo ether; else echo mesh; fi)"
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

  if [ $(cat /etc/hosts | grep -c "^$ip.*qmpadmin") -eq 0 ]; then
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
    community_node_id="$(qmp_uci_get node.community_node_id)"
  else
    community_node_id="$(qmp_get_mac_for_dev $primary_mesh_device | awk -F':' '{print $6}' )"
  fi

  local community_id="$(qmp_uci_get node.community_id)"
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

qmp_restart_firewall() {
	/etc/init.d/firewall restart
}

qmp_check_force_internet() {
	[ "$(qmp_uci_get networks.force_internet)" == "1" ] && qmp_gw_offer_default
	[ "$(qmp_uci_get networks.force_internet)" == "0" ] && qmp_gw_search_default
}

qmp_configure_initial() {
	qmp_hooks_exec firstboot
	qmp_configure_smart_network
}

qmp_configure() {
  qmp_hooks_exec preconf
  qmp_check_force_internet
  qmp_configure_network
  qmp_configure_bmx6
  qmp_configure_olsr6
  qmp_configure_lan_v6
  qmp_configure_system
  qmp_hooks_exec postconf
}

