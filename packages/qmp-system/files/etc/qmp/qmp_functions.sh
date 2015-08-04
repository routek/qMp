#!/bin/sh
# requires ip ipv6calc awk sed grep
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
[ -z "$SOURCE_SYS" ] && . $QMP_PATH/qmp_system.sh
[ -z "$SOURCE_WIRELESS" ] && . $QMP_PATH/qmp_wireless.sh
[ -z "$SOURCE_COMMON" ] && . $QMP_PATH/qmp_common.sh

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

# check if a device exists
qmp_check_device() {
	ip link show $1 1> /dev/null 2>/dev/null
	return $?
}

qmp_set_vlan() {
  local viface="$1" # lan/wan/meshX
  local vid=$2
  [ -z "$viface" ] || [ -z "$vid" ] && return

  uci set network.${viface}_${vid}=device
  if [ -e "/sys/class/net/$dev/phy80211" ]; then
    # 802.1Q VLANs for wireless interfaces
    uci set network.${viface}_${vid}.type=8021q
  else
    # [QinQ backport] 802.1q VLANs for wired interfaces
    uci set network.${viface}_${vid}.type=8021q
  fi
  uci set network.${viface}_${vid}.name=${viface}_${vid}
  if [ -e "/sys/class/net/$dev/phy80211" ]; then
    # 802.1Q VLANs for wireless interfaces
    uci set network.${viface}_${vid}.ifname='@'${viface}
  else
    # [QinQ backport] 802.1q VLANs for wired interfaces
    uci set network.${viface}_${vid}.ifname=$3
  fi
  uci set network.${viface}_${vid}.vid=${vid}

  uci set network.${viface}_${vid}_ad=interface
  uci set network.${viface}_${vid}_ad.ifname=${viface}_${vid}
  uci set network.${viface}_${vid}_ad.proto=${none}
  uci set network.${viface}_${vid}_ad.auto=1
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
		if [ ! -e "/sys/class/net/$device/phy80211" ]; then
			echo $viface
			return
		fi
  	fi

	for l in $(qmp_get_devices lan); do
		if [ "$l" == "$device" ]; then
			viface="lan"
			if [ ! -e "/sys/class/net/$device/phy80211" ]; then
				echo $viface
				return
			fi
		fi
	done

	[ ! -e "/sys/class/net/$device/phy80211" ] && [ -n "$viface" ] && { echo $viface; return; }

	# id is the first char and the numbers of the device [e]th[0] [w]lan[1]
	local id_num=$(echo $device | tr -d "[A-z]" | tr - _ | tr . _)
	local id_char=$(echo $device | cut -c 1)

	# is wan?
	for w in $(qmp_get_devices wan); do
		if [ "$w" == "$device" ]; then
			viface="wan_${id_char}${id_num}"
			echo $viface
			return
		fi
	done

	qmp_log "LOG: 5"
		qmp_log "Viface: $viface"

	# is mesh?
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

        # Looking if device is defined as LAN, in such case dev=br-lan, but only once
        # except eth1 for RouterStation Pro
        if ! ( [[ "$dev" == "eth1" ]] && qmp_is_routerstationpro ) ; then
            for landev in $(uci get qmp.interfaces.lan_devices 2>/dev/null); do
                if [ "$landev" == "$dev" ] && [ ! -e "/sys/class/net/$dev/phy80211" ] ; then
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

			# [Qin] The device might be a wired device (e.g. eth0) with a switch
			# and two or more virtual switched devices (e.g. eth0.1, eth0.2)
			for sdev in $(ls /sys/class/net/$dev/ | grep upper_$dev. | cut -d "_" -f2); do
				phydevs="$phydevs $sdev\n"
				ignore=1
			done

			if [ $ignore -eq 0 ]; then
				phydevs="$phydevs $dev\n"
			fi
		}
	done
	phydevs="$(echo -e "$phydevs" | grep -v -e ".*ap$" | sort -u | tr -d ' ' \t)"

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
		[ "$dev" == "eth0" ] || [ "$dev" == "eth0.1" ] && {
			lan="$lan $dev"
			mesh="$mesh $dev"
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

		# if there is already LAN device and it is not wifi, use as WAN+MESH
		[ -z "$wan" ] && wan="$dev" && mesh="$mesh $dev" || {
			# else use as LAN and MESH
			lan="$dev $lan"
			mesh="$dev $mesh"
		}

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

  # LoopBack device
  uci set $conf.loopback="interface"
  uci set $conf.loopback.ifname="lo"
  uci set $conf.loopback.proto="static"
  uci set $conf.loopback.ipaddr="127.0.0.1"
  uci set $conf.loopback.netmask="255.0.0.0"

  # WAN devices
  qmp_configure_wan
  # LAN devices
  qmp_configure_lan
  # MESH devices
  qmp_configure_mesh

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
	local t
	config_get ignore "$section" ignore

	[ "$ignore" = "1" ] && return

	local type="$(qmp_uci_get_raw gateways.$name.type)"
	qmp_log Configuring gateway $name of type $type
	[ -z "$name" ] && name="qmp_$gateway" || name="qmp_$name"

	if [ "$type" == "offer" ]
	then
		bmx6_type=tunIn
		uci set $config.$name="$bmx6_type"
		uci set $config.$name.$bmx6_type="$name"
		for t in \
			network \
			bandwidth
		do
			qmp_translate_configuration gateways $section $t $config $name
		done
	else
		bmx6_type=tunOut
		uci set $config.$name="$bmx6_type"
		uci set $config.$name.$bmx6_type="$section"
		for t in \
			network \
			srcNet \
			gwName \
			minPrefixLen \
			maxPrefixLen \
			hysteresis \
			rating \
			minBandwidth \
			tableRule \
			kernel \
			boot \
			static \
			zebra \
			system \
			connect \
			rip \
			ripng \
			ospf \
			ospf6 \
			isis \
			bgp \
			babel \
			olsr \
			exportDistance \
			srcType \
			gwId \
			ipMetric
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

  local community_node_id=$(qmp_get_id)

  if qmp_uci_test qmp.interfaces.mesh_devices &&
  qmp_uci_test qmp.networks.mesh_protocol_vids

    then
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

	# Check if the protocol has VLAN tag configured
	local vid="$(echo $protocol_vid | awk -F':' '{print $2}')"
	[ -z "$vid" -o $vid -lt 1 ] && use_vlan=0

	# Check if the protocol has VLAN tag configured
	local vid="$(echo $protocol_vid | awk -F':' '{print $2}')"
	[ -z "$vid" -o $vid -lt 1 ] && use_vlan=0

	# If vlan tagging
		if [ $use_vlan -eq 1 ]; then
			local viface="$(qmp_get_virtual_iface $dev)"
			local ifname="${viface}_${vid}"
			
	# If not vlan tagging
		else
			local ifname="$dev"
		fi

		uci set $conf.mesh_$counter="dev"
		uci set $conf.mesh_$counter.dev="$ifname"
		if [ -e "/sys/class/net/$dev/phy80211" ]; then
			uci set $conf.mesh_$counter.linklayer=2
		else
			uci set $conf.mesh_$counter.linklayer=1
		fi

	    if qmp_uci_test qmp.networks.bmx6_ipv4_address ; then
	      local bmx6_ipv4_netmask="$(echo $(uci get qmp.networks.bmx6_ipv4_address) | cut -s -d / -f2)"
	      local bmx6_ipv4_address="$(echo $(uci get qmp.networks.bmx6_ipv4_address) | cut -d / -f1)"
	      [ -z "$bmx6_ipv4_netmask" ] && bmx6_ipv4_netmask="32"
	      uci set $conf.general.tun4Address="$bmx6_ipv4_address/$bmx6_ipv4_netmask"
	      uci set $conf.tmain=tunDev
	      uci set $conf.tmain.tunDev=tmain
	      uci set $conf.tmain.tun4Address="$bmx6_ipv4_address/$bmx6_ipv4_netmask"

	    else
	      local ipv4_suffix24="$(qmp_get_id 8bit)"
	      local ipv4_prefix24="$(qmp_uci_get networks.bmx6_ipv4_prefix24)"
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

qmp_restart_firewall() {
	iptables -F
	iptables -F -t nat
	sh /etc/firewall.user
}

qmp_check_force_internet() {
	[ "$(qmp_uci_get networks.force_internet)" == "1" ] && qmp_gw_offer_default
	[ "$(qmp_uci_get networks.force_internet)" == "0" ] && qmp_gw_search_default
}

qmp_configure_initial() {
	qmp_hooks_exec firstboot
	qmp_configure_wifi_initial
	qmp_configure_wifi
	/etc/init.d/network reload
	sleep 1
	qmp_configure_smart_network
}

qmp_configure() {
  qmp_configure_system
  qmp_set_services
  qmp_hooks_exec preconf
  qmp_check_force_internet
  qmp_configure_network
  qmp_configure_bmx6
  qmp_configure_lan_v6
  qmp_hooks_exec postconf
}

