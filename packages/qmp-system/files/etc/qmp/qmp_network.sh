#!/bin/sh
##############################
# Global variable definition
##############################
QMP_PATH="/etc/qmp"
TMP="/tmp"
QMPINFO="/etc/qmp/qmpinfo"

#######################
# Importing files
######################
SOURCE_NET=1
[ -z "$SOURCE_COMMON" ] && . $QMP_PATH/qmp_common.sh
[ -z "$SOURCE_FUNCTIONS" ] && . $QMP_PATH/qmp_functions.sh
[ -z "$SOURCE_SYS" ] && . $QMP_PATH/qmp_system.sh

# Adds the iptables mss clamping rule for descovering maximum MSS
# <device> [remove]
qmp_set_mss_clamping_and_masq() {
    local dev="$1"
    local rm="$2"
    local fw="/etc/firewall.user"
    for rule in "iptables -A FORWARD -p tcp -o $dev -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu" \
                "iptables -t nat -A POSTROUTING -o $dev ! -d 10.0.0.0/8 -j MASQUERADE"; do
	  [ -z "$dev" ] && return
	  if [ "$rm" == "remove" ]; then
	    sed -i /"$(echo $rule | sed s?'/'?'\\/'?g)"/d $fw
      else if [ $(cat $fw | grep "$rule" -c) -eq 0 ]; then
        qmp_log "Adding TCP ClampMSS rule for $dev"
        echo "$rule" >> $fw
      fi;fi
    done
}

# Prepare config files
qmp_configure_prepare_network() {
	local toRemove="$(uci show network | egrep "network.(lan|wan|mesh_).*=(interface|device)" | cut -d. -f2 | cut -d= -f1)"
	qmp_log "Removing current network configuration"
	for i in $toRemove; do
		uci del network.$i
	done
	uci commit network
}

## DISABLED
# Publish or unpublish lan HNA depending on qmp configuration
qmp_publish_lan() {
	echo "Publish LAN is a garbage, doing nothing..."
	return

	is_publish_on=$(qmp_uci_get networks.publish_lan)
	[ -z "$is_publish_on" ] && is_publish_on=0

	if [ $is_publish_on -eq 1 ]; then
		lan_addr=$(qmp_uci_get networks.lan_address)
		lan_mask=$(qmp_uci_get networks.lan_netmask)
		lan_prefix=$(qmp_get_prefix_from_netmask $lan_mask)
		lan_netid=$(qmp_get_netid_from_network $lan_addr $lan_mask)

		echo "Publishing LAN network: $lan_netid/$lan_prefix"
		qmp_publish_hna_bmx6 $lan_netid/$lan_prefix qMp_lan
	else
		qmp_unpublish_hna_bmx6 qMp_lan
	fi
}

# Usage: qmp_publish_hna_bmx6 <NETADDR/PREFIX> [Name ID]
# Example: qmp_publish_hna_bmx6 fd00:1714:1714::/64 my_lan
qmp_publish_hna_bmx6() {
	local netid=$(echo $1 | cut -d / -f1)
	local netmask=$(echo $1 | cut -d / -f2)
	local name_id="$2"

	[ -z "$netid" -o -z "$netmask" ] && { echo "Error, IP/MASK must be specified"; return; }

	local is_ipv6=$(echo $netid | grep : -c)
	[ $is_ipv6 -lt 1 ] && { echo "Error in IPv6/Prefix format"; return; }

	if [ -z "$name_id" ]; then
		local ucfg=$(uci add bmx6 unicastHna)
		[ -z "$ucfg" ] && { echo "Cannot add unicastHna entry to UCI"; return; }
		uci set bmx6.$ucfg.unicastHna="$netid/$netmask"
	else
		uci set bmx6.$name_id=unicastHna
		uci set bmx6.$name_id.unicastHna="$netid/$netmask"
	fi

	uci commit bmx6

	bmx6 -c --test -u $netid/$netmask > /dev/null
	if [ $? -eq 0 ]; then
		bmx6 -c --configReload
	else
		echo "ERROR in bmx6, check log"
	fi
}

# Unpublish a HNA, first argument is IPv6 HNA or name id
qmp_unpublish_hna_bmx6() {
	if [ $(echo $1 | grep : -c) -ne 0 ]; then
		uci show bmx6.@unicastHna[].unicastHna | while read hna
			do
			if [ "$(echo $hna | cut -d= -f2)" == "$1" ]; then
				uci del bmx6.$(echo $hna | cut -d. -f2)
				return
			fi
			done
	else
		uci delete bmx6.$1
	fi

	uci commit
	bmx6 -c --configReload
}

### Deprecated
qmp_radvd_enable_dev() {
	local dev="$1"
	local cfg=""
	echo "Enabling interface $1 for radvd"

	for i in $(uci show radvd.@interface[].interface 2>/dev/null); do
		if [ "$(echo $i | cut -d= -f2)" == "$dev" ]; then
			cfg="$(echo $i | cut -d. -f2)"
			break
		fi
	done

	if [ -z "$cfg" ]; then
		echo "Cannot find radvd config for $dev. Addind new one"
		cfg="$(uci add radvd interface)"
		uci set radvd.$cfg.interface=$dev
	fi

	uci set radvd.$cfg.ignore=0
	uci set radvd.$cfg.AdvSendAdvert=1
	uci set radvd.$cfg.AdvManagedFlag=1
	uci set radvd.$cfg.IgnoreIfMissing=1
	uci commit
	echo "Done"
}

### Deprecated
qmp_radvd_enable_prefix() {
	local dev="$1"
	local prefix="$2"
	echo "Adding prefix $route $dev to radvd"
	[ -z "$dev" -o -z "$prefix" ] && { echo "Dev or route missing, exiting"; return; }

	# Looking for the already configured device
	local cfg=""
	for i in $(uci show radvd.@prefix[].interface 2>/dev/null); do
		if [ "$(echo $i | cut -d= -f2)" == "$dev" ]; then
			cfg="$(echo $i | cut -d. -f2)"
			break
		fi
	done

	# Checking if this prefix already exists in the device
	for p in $(uci get radvd.$cfg.prefix 2>/dev/null); do
		if [ "$p" == "$prefix" ]; then
			echo "Prefix found in $dev radvd configuration, nothing to do"
			return
		fi
	done

	# If the configuration is not found, creating new one"
	if [ -z "$cfg" ]; then
		cfg=$(uci add radvd prefix)
		uci set radvd.$cfg.interface=$dev
	fi

	# Configuring parameters of radvd
	uci set radvd.$cfg.ignore=0
	uci set radvd.$cfg.AdvOnLink=1
	uci add_list radvd.$cfg.prefix=$prefix
	uci commit

	echo "Done"
}

### Deprecated
qmp_radvd_enable_route() {
	local dev="$1"
	local route="$2"
	echo "Adding route $route $dev to radvd"
	[ -z "$dev" -o -z "$route" ] && { echo "Dev or route missing, exiting"; return; }

	# Looking for the already configured device
	local cfg=""
	for i in $(uci show radvd.@route[].interface 2>/dev/null); do
		if [ "$(echo $i | cut -d= -f2)" == "$dev" ]; then
			cfg="$(echo $i | cut -d. -f2)"
			break
		fi
	done

	# Checking if this prefix already exists in the device
	for p in $(uci get radvd.$cfg.prefix 2>/dev/null); do
		if [ "$p" == "$route" ]; then
			echo "Prefix found in $dev radvd configuration, nothing to do"
			return
		fi
	done

	# If the configuration is not found, creating new one"
	if [ -z "$cfg" ]; then
		cfg=$(uci add radvd route)
		uci set radvd.$cfg.interface=$dev
	fi

	# Configuring parameters of radvd
	uci set radvd.$cfg.ignore=0
	uci set radvd.$cfg.AdvRouteLifetime="infinity"
	uci add_list radvd.$cfg.prefix=$route
	uci commit

	echo "Done"
}

qmp_configure_lan_v6() {
	qmp_log "Starting ULA LAN configuration"

	local prefix="$(qmp_uci_get networks.lan_ula_prefix48)"
	[ -z "$prefix" ] && { echo "No lan ULA prefix configured, skiping LAN IPv6 ULA configuration"; return; }

	local dev="$(qmp_uci_get node.primary_device)"

	if [ -z "$dev" ]; then
		lanid="$(cat /var/log/*.log | md5sum | awk '{print $1}' | cut -c1-4)"
	else
		lanid="$(qmp_get_id)"
	fi

	if [ $(echo $prefix | grep :: -c) -eq 0 ]; then
		ulan_net="$prefix:$lanid::/64"
		ulan_ip="$prefix:$lanid::1/64"
	else
		ulan_net="$prefix:$lanid:0000:0000:0000:0000/64"
		ulan_ip="$prefix:$lanid:0000:0000:0000:0001/64"
	fi

	echo "Configuring $ulan_ip as LAN ULA address"
	qmp_uci_set_raw network.lan.ip6addr=$ulan_ip
	ifup lan
	echo "Publishing $ulan_net over the mesh network"
	qmp_publish_hna_bmx6 $ulan_net ulan

	
	### Deprecated
	# echo "Configuring radvd"
	# qmp_radvd_enable_dev lan
	# qmp_radvd_enable_prefix lan $ulan_ip
	# qmp_radvd_enable_route lan fc00::/7
	# /etc/init.d/radvd restart

	echo "Done"
}

# configure LAN devices
qmp_configure_lan() {
  # Set some important variables
  local dns="$(qmp_uci_get networks.dns)"
  local lan_mask="$(qmp_uci_get networks.lan_netmask)"
  local lan_addr="$(qmp_uci_get networks.lan_address)"

  # If the lan address is empty in the configuration
  [ -z "$lan_addr" ] && {
    [ $(qmp_uci_get roaming.ignore) -eq 0 ] && {
      lan_addr="172.30.22.1"
      lan_mask="255.255.0.0"
      qmp_log No LAN ip address configured, roaming mode enabled, autoconfiguring $lan_addr/$lan_mask
    } || {
      lan_addr="10.$(qmp_get_id_ip 1).$(qmp_get_id_ip 2).1"
      lan_mask="255.255.255.0"
      qmp_uci_set networks.bmx6_ipv4_address $lan_addr/24
      qmp_log No LAN ip address configured, community mode enabled, autoconfiguring $lan_addr/$lan_mask
    }
    qmp_uci_set networks.lan_address $lan_addr
    qmp_uci_set networks.lan_netmask $lan_mask
  }

  # If layer3 roaming enabled, check it is configured properly
  # last byte of lan adress must be "1" to avoid overlappings
  # mask must be /16
  if [ $(qmp_uci_get roaming.ignore) -eq 0 ]; then
     lan_mask="255.255.0.0"
     lan_addr=$(echo $lan_addr | sed -e 's/\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)\.[0-9]\{1,3\}/\1.1/1')
     qmp_uci_set networks.lan_address $lan_addr
     qmp_uci_set networks.lan_netmask $lan_mask
  fi

  # Configure DHCP
  qmp_configure_dhcp

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
    qmp_set_mss_clamping_and_masq $device remove
  done
}

# configure WAN devices
qmp_configure_wan() {
	for i in $(qmp_get_devices wan) ; do
		echo "Configuring $i in WAN mode"
		local viface="$(qmp_get_virtual_iface $i)"
		qmp_uci_set_raw network.$viface="interface"
		qmp_attach_device_to_interface $i $viface
		qmp_uci_set_raw network.$viface.proto="dhcp"
		metric="$(qmp_uci_get network.wan_metric)"
		[ -n "$metric" ] && qmp_uci_set_raw network.$viface.metric="$metric"
		qmp_gw_masq_wan 1
		qmp_set_mss_clamping_and_masq $i
	done

}

# MESH devices configuration
qmp_configure_mesh() {
	local counter=1

	if qmp_uci_test qmp.interfaces.mesh_devices &&
	qmp_uci_test qmp.networks.mesh_protocol_vids; then

	for dev in $(qmp_get_devices mesh); do
		echo "Configuring "$dev" for Meshing"

		# Check if the current device is configured as no-vlan
		local use_vlan=1
		for no_vlan_int in $(qmp_uci_get interfaces.no_vlan_devices 2>/dev/null); do
			[ "$no_vlan_int" == "$dev" ] && use_vlan=0
		done

		local protocol_vids="$(qmp_uci_get networks.mesh_protocol_vids 2>/dev/null)"
		[ -z "$protocol_vids" ] && protocol_vids="bmx6:12"

		local primary_mesh_device="$(qmp_get_primary_device)"

		for protocol_vid in $protocol_vids; do
			local protocol_name="$(echo $protocol_vid | awk -F':' '{print $1}')"
			local vid="$(echo $protocol_vid | awk -F':' '{print $2}')"

			# if no vlan is specified do not use vlan
			[ -z "$vid" ] && vid=1 && use_vlan=0

			# if no vlan is specified do not use vlan
			[ -z "$vid" ] && vid=1 && use_vlan=0

			# virtual interface
			local viface=$(qmp_get_virtual_iface $dev)

			# put typical IPv6 prefix (2002::), otherwise ipv6 calc assumes mapped or embedded ipv4 address
			local ip6_suffix="2002::${counter}${vid}"

			# Since all interfaces are defined somewhere (LAN, WAN or with Rescue IP),
			# in case of not use vlan tag, device definition is not needed.
			[ $use_vlan -eq 1 ] && {

				#### [QinQ]
				####
				#### Using the rescue interface here does not make much sense as of
				#### current qMp status and does not work for 802.1-ad
				####
				#### # If device is WAN use rescue for the VLAN tag
				####
				####	if [ $(qmp_get_devices wan | grep -c $dev) -gt 0 ]; then
				####		qmp_set_vlan ${viface}_rescue $vid $dev
				####	else
				####		qmp_set_vlan $viface $vid $dev
				####	fi

				qmp_set_vlan $viface $vid $dev
			}

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

		qmp_configure_rescue_ip_device "$dev" "$viface"
		counter=$(( $counter + 1 ))
	done
	fi
}

# rescue IP configuration functions

qmp_configure_rescue_ip_device() {
	local dev="$1"
	local viface="$2"

	if qmp_is_in "$dev" $(qmp_get_devices wan) || [ "$dev" == "br-lan" ]; then
		# If it is WAN or LAN
		qmp_configure_rescue_ip $dev ${viface}_rescue
		qmp_attach_device_to_interface $dev ${viface}_rescue
	elif qmp_is_in "$dev" $(qmp_get_devices mesh) && [ "$dev" != "br-lan" ]; then
		# If it is only mesh device
		qmp_configure_rescue_ip $dev
		qmp_attach_device_to_interface $dev $viface
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

# apply the non-overlapping DHCP-range preset policy
# qmp_configure_dhcp <node_id>
qmp_configure_dhcp() {
	local community_node_id="$1"
	local start=2
	local limit=253
	local leasetime="$(qmp_uci_get non_overlapping.qmp_leasetime)"
	leasetime=${leasetime:-1h}

	# If DHCP non overlapping enabled, configuring it (this is the layer3 roaming)
	if [ "$(qmp_uci_get non_overlapping.ignore)" == "0" ]; then
		echo "Configuring DHCP non-overlapping (roaming mode)"
		local num_grp=256
		local uci_offset="$(qmp_uci_get non_overlapping.dhcp_offset)"
		uci_offset=${uci_offset:-2}
		local offset=0
		[ $uci_offset -lt $num_grp ] && offset=$uci_offset
		start=$(( 0x$community_node_id * $num_grp + $offset ))
		limit=$(( $num_grp - $offset ))
	fi

	# Setting values
	echo "Setting up DHCP server in LAN interface"
	qmp_uci_set_raw dhcp.lan="dhcp"
	qmp_uci_set_raw dhcp.lan.interface="lan"
	qmp_uci_set_raw dhcp.lan.leasetime="$leasetime"
	qmp_uci_set_raw dhcp.lan.start="$start"
	qmp_uci_set_raw dhcp.lan.limit="$limit"

	# If disable_lan_dhcp=1 disable DHCP server
	if [ "$(qmp_uci_get networks.disable_lan_dhcp)" == "1" ]; then
		echo "DHCP server disabled in LAN interface"
		qmp_uci_set_raw dhcp.lan.ignore="1"
	else
		qmp_uci_set_raw dhcp.lan.ignore="0"
	fi

	# Set dhcp server in mesh devices if enabled
	if [ "$(qmp_uci_get networks.disable_mesh_dhcp)" == "0" ]; then
		local dev
		for dev in $(qmp_get_devices mesh); do
			local vif="$(qmp_get_virtual_iface $dev)"
			[ -n "$vif" ] && {
				qmp_log "Configuring dhcp server for mesh device $dev/$vif"
				qmp_uci_set_raw dhcp.$vif="dhcp"
				qmp_uci_set_raw dhcp.$vif.interface="$vif"
				qmp_uci_set_raw dhcp.$vif.leasetime="10m"
				qmp_uci_set_raw dhcp.$vif.ignore="0"
			}
		done
	fi
}

qmp_bmx6_reload() {
	local restart_bmx6=false

	local bmx6_name="$(bmx6 -c status | awk 'END{split($4,f,"."); print f[1]}')"
	local current_hostname="$(cat /proc/sys/kernel/hostname)"
	if [ "$current_hostname" != "$bmx6_name" ]
	then
        	restart_bmx6=true
	fi

	if ! $restart_bmx6
	then
		if ! bmx6 -c --configReload
		then
			restart_bmx6=true
		fi
	fi

	if $restart_bmx6
	then
		/etc/init.d/bmx6 restart
	fi
}
