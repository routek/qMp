#!/bin/sh /etc/rc.common
#START=91


# requires ip ipv6calc awk sed grep


qmp_uci_test() {

  option=$1

  if uci get $option > /dev/null 2>&1 ; then
    return 0
  fi

  return 1
}

qmp_get_mac_for_dev() {
  local dev=$1
  ip addr show dev $dev | grep -m 1 "link/ether" | awk '{print $2}'
}

qmp_get_llocal_for_dev() {
  local dev=$1
  ip a show dev $dev | grep inet6 | awk '{print $2}'
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

  if qmp_uci_test qmp.interfaces.wan_device ; then
    uci set $conf.wan="interface"
    uci set $conf.wan.ifname="$(uci get qmp.interfaces.wan_device)"
    uci set $conf.wan.proto="dhcp"
  fi


  uci set $conf.niit4to6="interface"
  uci set $conf.niit4to6.proto="none"
  uci set $conf.niit4to6.ifname="niit4to6"
  
  uci set $conf.niit6to4="interface"
  uci set $conf.niit6to4.proto="none"
  uci set $conf.niit6to4.ifname="niit6to4"

  local primary_mesh_device="$(uci get qmp.interfaces.mesh_devices | awk '{print $1}')"
  local community_node_id
  if qmp_uci_test qmp.node.community_node_id; then
    community_node_id="$(uci get qmp.node.community_node_id)"
  elif ! [ -z "$primary_mesh_device" ] ; then
    community_node_id="$( qmp_get_mac_for_dev $primary_mesh_device | awk -F':' '{print $6}' )"
  fi

  if qmp_uci_test qmp.interfaces.lan_devices ; then

    uci set $conf.lan="interface"
    uci set $conf.lan.ifname="$(uci get qmp.interfaces.lan_devices)"
#    uci set $conf.lan.type="bridge"
    uci set $conf.lan.proto="static"
    uci set $conf.lan.ipaddr="$(uci get qmp.networks.lan_address)"
    uci set $conf.lan.netmask="$(uci get qmp.networks.lan_netmask)"
    uci set $conf.lan.dns="(uci get qmp.networks.dns)"


    if qmp_uci_test qmp.interfaces.mesh_devices && qmp_uci_test qmp.networks.mesh_protocol_vids; then

      for protocol_vid in $(uci get qmp.networks.mesh_protocol_vids); do

        local protocol_name="$(echo $protocol_vid | awk -F':' '{print $1}')"
        local lan="niit4to6_${protocol_name}"

	uci set $conf.$lan="alias"
	uci set $conf.$lan.interface="niit4to6"
	uci set $conf.$lan.proto="static"

        if qmp_uci_test qmp.networks.${protocol_name}_ripe_prefix48 ; then

          local ripe_prefix48="$(uci get qmp.networks.${protocol_name}_ripe_prefix48)"
          uci set $conf.$lan.ip6addr="$(qmp_get_addr64 $ripe_prefix48:: $community_node_id ::1 64)"
        fi

        if qmp_uci_test qmp.networks.${protocol_name}_ipv4_address && qmp_uci_test qmp.networks.${protocol_name}_ipv4_netmask ; then
          uci set $conf.$lan.ipaddr="$(uci get qmp.networks.${protocol_name}_ipv4_address)"
          uci set $conf.$lan.netmask="$(uci get qmp.networks.${protocol_name}_ipv4_netmask)"
        elif qmp_uci_test qmp.networks.${protocol_name}_ipv4_prefix24 && ! [ -z "$community_node_id" ] ; then
	  local ipv4_suffix24="$(( 0x$community_node_id / 0x100 )).$(( 0x$community_node_id % 0x100 ))"
          uci set $conf.$lan.ipaddr="$(uci get qmp.networks.${protocol_name}_ipv4_prefix24).$ipv4_suffix24"
          uci set $conf.$lan.netmask="255.255.255.255"
        fi

      done
    fi
  fi


  local counter=1

  if uci get qmp.interfaces.mesh_devices && uci get qmp.networks.mesh_protocol_vids && uci get qmp.networks.mesh_vid_offset; then

    for dev in $(uci get qmp.interfaces.mesh_devices); do 
       for protocol_vid in $(uci get qmp.networks.mesh_protocol_vids); do

         local protocol_name="$(echo $protocol_vid | awk -F':' '{print $1}')"
         local vid_suffix="$(echo $protocol_vid | awk -F':' '{print $2}')"
         local vid_offset="$(uci get qmp.networks.mesh_vid_offset)"
         local vid="$(( $vid_offset + $vid_suffix ))"

         local mesh="mesh_${protocol_name}_${counter}"
         local ip6_suffix="2002::${counter}${vid_suffix}" #put typical IPv6 prefix (2002::), otherwise ipv6 calc assumes mapped or embedded ipv4 address

         if qmp_uci_test qmp.networks.${protocol_name}_mesh_prefix48; then
           uci set $conf.$mesh="interface"
           uci set $conf.$mesh.ifname="$dev.$vid"
           uci set $conf.$mesh.proto="static"
           uci set $conf.$mesh.ip6addr="$(qmp_get_ula96 $(uci get qmp.networks.${protocol_name}_mesh_prefix48):: $primary_mesh_device $ip6_suffix 128)"
         fi

       done

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
  uci set $conf.general.globalPrefix="$(uci get qmp.networks.bmx6_mesh_prefix48)::/48"

  uci set $conf.bmx6_config_plugin=plugin
  uci set $conf.bmx6_config_plugin.plugin=bmx6_config.so

  uci set $conf.bmx6_json_plugin=plugin
  uci set $conf.bmx6_json_plugin.plugin=bmx6_json.so

  uci set $conf.ipVersion=ipVersion
  uci set $conf.ipVersion.ipVersion="6"
  uci set $conf.ipVersion.throwRules="0"


  local primary_mesh_device="$(uci get qmp.interfaces.mesh_devices | awk '{print $1}')"
  local community_node_id
  if qmp_uci_test qmp.node.community_node_id; then
    community_node_id="$(uci get qmp.node.community_node_id)"
  elif ! [ -z "$primary_mesh_device" ] ; then
    community_node_id="$( qmp_get_mac_for_dev $primary_mesh_device | awk -F':' '{print $6}' )"
  fi

  if qmp_uci_test qmp.interfaces.mesh_devices && qmp_uci_test qmp.networks.mesh_protocol_vids && qmp_uci_test qmp.networks.mesh_vid_offset; then

    local counter=1

    for dev in $(uci get qmp.interfaces.mesh_devices); do 
       for protocol_vid in $(uci get qmp.networks.mesh_protocol_vids); do

         local protocol_name="$(echo $protocol_vid | awk -F':' '{print $1}')"

         if [ "$protocol_name" = "bmx6" ] ; then

            local vid_suffix="$(echo $protocol_vid | awk -F':' '{print $2}')"
            local vid_offset="$(uci get qmp.networks.mesh_vid_offset)"
	    local ifname="$dev.$(( $vid_offset + $vid_suffix ))"

	    uci set $conf.mesh_$counter="dev"
	    uci set $conf.mesh_$counter.dev="$ifname"

	    if qmp_uci_test qmp.networks.bmx6_ipv4_address ; then
	      uci set $conf.general.tun4Address="$(uci get qmp.networks.bmx6_ipv4_address)"
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
  fi


  if qmp_uci_test qmp.tunnels.search_ipv4_tunnel ; then
    uci set $conf.tun4Out="tunOut"
    uci set $conf.tun4Out.tunOut="tun4Out"
    uci set $conf.tun4Out.network="$(uci get qmp.tunnels.search_ipv4_tunnel)"

  elif qmp_uci_test qmp.tunnels.offer_ipv4_tunnel ; then
    uci set $conf.tunInRemote="tunInRemote"
    uci set $conf.tunInRemote.tunInRemote="$(qmp_get_ula96 $(uci get qmp.networks.bmx6_mesh_prefix48):: $primary_mesh_device 2002::ffff )"

    uci set $conf.tun4InNet="tunInNet"
    uci set $conf.tun4InNet.tunInNet="$(uci get qmp.tunnels.offer_ipv4_tunnel)"
    uci set $conf.tun4InNet.bandwidth="1000000"
  fi



 

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

  local primary_mesh_device="$(uci get qmp.interfaces.mesh_devices | awk '{print $1}')"
  local community_node_id
  if qmp_uci_test qmp.node.community_node_id; then
    community_node_id="$(uci get qmp.node.community_node_id)"
  elif ! [ -z "$primary_mesh_device" ] ; then
    community_node_id="$( qmp_get_mac_for_dev $primary_mesh_device | awk -F':' '{print $6}' )"
  fi


  if qmp_uci_test qmp.interfaces.mesh_devices && qmp_uci_test qmp.networks.mesh_protocol_vids && qmp_uci_test qmp.networks.mesh_vid_offset; then

    local counter=1

    for dev in $(uci get qmp.interfaces.mesh_devices); do 
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







qmp_configure_olsr6_uci_unused() {

  local conf="olsrd_uci"

  qmp_configure_prepare $conf


  uci set $conf.networks="olsrd"
  uci set $conf.networks.IpVersion="6"

  uci set $conf.arprefresh="LoadPlugin"
  uci set $conf.arprefresh.library="olsrd_arprefresh.so.0.1"

  uci set $conf.httpinfo="LoadPlugin"
  uci set $conf.httpinfo.library="olsrd_httpinfo.so.0.1"
  uci set $conf.httpinfo.port="1978"
  uci add_list $conf.httpinfo.Net="0::/0"

  uci set $conf.nameservice="LoadPlugin"
  uci set $conf.nameservice.library="olsrd_nameservice.so.0.3"

  uci set $conf.txtinfo="LoadPlugin"
  uci set $conf.txtinfo.library="olsrd_txtinfo.so.0.1"
  uci set $conf.txtinfo.accept="0::"

  if qmp_uci_test qmp.interfaces.mesh_devices && qmp_uci_test qmp.networks.mesh_protocol_vids && qmp_uci_test qmp.networks.mesh_vid_offset; then

    local counter=1
    local interface_list=""

    for dev in $(uci get qmp.interfaces.mesh_devices); do 
       for protocol_vid in $(uci get qmp.networks.mesh_protocol_vids); do

         local protocol_name="$(echo $protocol_vid | awk -F':' '{print $1}')"

         echo "qmp_configure_olsr6 dev=$dev protocol_vid=$protocol_vid protocol_name=$protocol_name"

         if [ "$protocol_name" = "olsr6" ] ; then

            local vid_suffix="$(echo $protocol_vid | awk -F':' '{print $2}')"
            local vid_offset="$(uci get qmp.networks.mesh_vid_offset)"
	    local interface="olsr6_${counter}"
	    local ifname="$dev.$(( $vid_offset + $vid_suffix ))"

            echo "adding ifname=$ifname interface=$interface"

            interface_list="$interface_list $interface"

         fi

       done
    done
 
    uci set $conf.interface="Interface"
    uci add_list $conf.interface.interface="$interface_list"

  fi
  
  uci commit $conf
#  /etc/init.d/$conf restart
}


qmp_configure_system() {

  local primary_mesh_device="$(uci get qmp.interfaces.mesh_devices | awk '{print $1}')"
  local community_node_id
  if qmp_uci_test qmp.node.community_node_id; then
    community_node_id="$(uci get qmp.node.community_node_id)"
  elif ! [ -z "$primary_mesh_device" ] ; then
    community_node_id="$( qmp_get_mac_for_dev $primary_mesh_device | awk -F':' '{print $6}' )"
  fi

  uci set system.@system[0].hostname=qmp${community_node_id}
  uci commit system

  # enable IPv6 in httpd:
  uci set uhttpd.main.listen_http="80"
  uci set uhttpd.main.listen_https="443"
  uci commit uhttpd
  /etc/init.d/uhttpd restart
}




qmp_configure() {

  qmp_configure_network
  qmp_configure_bmx6
  qmp_configure_olsr6
  qmp_configure_system

}



