#!/bin/sh /etc/rc.common
#Variable in upper case
#Tabular insertions according to GSF code standards
#Creation logging messages format
#Renaming variables and functions names according to standard nomenclature about IPv6 adressing scheme
#IPv4 and IPv6 variables naming, under unified criteria:
#IP6_GLOBAL_PREFIX{M1}
#IP6_ULA_PREFIX
#IP{P}_SUBNETID{M2}
#IP{P}_IFACEID{M3}
#P={4,6] Mi=Number of bits => Sum(Mi)=128/32 in IPv6/IPv4
#VID assigment method is more flexible. We admit in UCI variable 'option mesh_protocol_vids' the notation: mesh_devN[:vid], where vid is optional. More convenient in switched environment based in cable
#If none VID is supplied it is assumed 'option mesh_vid_offset' value, with incremental progression through the meshing network interfaces
#Main idea:
#Only one global and ULA prefix for community. Therefore a community is a node network with common global prefix.
#Each node have a community_node_id (12bits). The administrator have to check the unicity of this number inside the community. If none number os supplied, the last 12 bits of main MAC address wirl be used
#Each protocol will have 4bits (from 0 to F)
# [GLOBAL PREFIX 48]:[COMM-NUMBER 12 | PROTOCOL NUMBER 4]:1
# [ULA PREFIX 48]:[MAC-ADDRESS 48]:[COMM-NUMBER 12 | PROTOCOL NUMBER 4]:1

#START=91


# requires ip ipv6calc awk sed grep

#Required UCI section names
BASE_CONFIG=network
QMP_CONFIG=qmp
BMX6_CONFIG=bmx6
OLSR6_CONFIG=olsrd
OLSR6_UCI_CONFIG=olsrd_uci

#Canonical names of protocols
BMX6_CNAME=bmx6
OLSR6_CNAME=olsr6

LOGFILE=/tmp/qmp.log

#Set UCI-options function
qmp_set_option(){

	local UCI_ARG=$1
	local VALUE=$2
	local SOURCE=$3

	if [ -z "$SOURCE" ]
	then
		SOURCE="qmp_set_option"
	fi

	if [ -z "$UCI_ARG" ]
	then
		qmp_log_file "$SOURCE" "Setting UCI config parameter" "Nothing to set"
	else

		if uci set $UCI_ARG="$VALUE" &> /dev/null
		then
			#qmp_log_all "$SOURCE" "Setting UCI '$UCI_ARG'" "Done"h
			qmp_log_file "$SOURCE" "Setting UCI '$UCI_ARG'='$VALUE', uci get $UCI_ARG='$(uci get $UCI_ARG)'" "Done" 
		else
			#qmp_log_all "$SOURCE" "Setting UCI '$UCI_ARG'" "Failed"
			qmp_log_file "$SOURCE" "Setting UCI '$UCI_ARG'='$VALUE', returned '$(uci set $UCI_ARG=$VALUE 2>&1)'" "Error"
		fi
	fi

}

#Get UCI-options function
qmp_get_option(){

	local UCI_ARG=$1
	local SOURCE=$2

	if [ -z "$SOURCE" ]
	then
		SOURCE="qmp_get_option"
	fi

	if [ -z "$UCI_ARG" ]
	then
		#qmp_log_all "$SOURCE" "Getting UCI config parameter" "[Nothing to get]"
		qmp_log_file "$SOURCE" "Getting UCI argument" "Nothing to get"
	else
		if uci get $UCI_ARG &> /dev/null
		then
			uci get $UCI_ARG
			#qmp_log_all "$SOURCE" "Getting UCI '$UCI_ARG'" "Done"
			qmp_log_file "$SOURCE" "Getting UCI '$UCI_ARG', uci get $UCI_ARG='$(uci get $UCI_ARG)'" "Done"
		else
			#qmp_log_all "$SOURCE" "Getting UCI '$UCI_ARG'" "Failed"
			qmp_log_file "$SOURCE" "Getting UCI '$UCI_ARG', returned '$(uci get $UCI_ARG 2>&1)'" "Error"
		fi
	fi

}

#Add UCI-sections function
qmp_add_option(){

	local UCI_ARG=$1
	local VALUE=$2
	local SOURCE=$3

	if [ -z "$SOURCE" ]
	then
		SOURCE="qmp_add_option"
	fi

	if [ -z "$UCI_ARG" ]
	then
		qmp_log_file "$SOURCE" "Adding UCI config parameter" "Nothing to set"
	else

		if uci add $UCI_ARG=$VALUE &> /dev/null
		then
			#qmp_log_all "$SOURCE" "Adding UCI '$UCI_ARG'" "Done"
			qmp_log_file "$SOURCE" "Adding UCI '$UCI_ARG'='$VALUE'" "Done"
		else
			#qmp_log_all "$SOURCE" "Adding UCI '$UCI_ARG'" "Failed"
			qmp_log_file "$SOURCE" "Adding UCI '$UCI_ARG'='$VALUE', returned '$(uci add $UCI_ARG=$VALUE 2>&1)'" "Error"
		fi
	fi

}

#Backup the original config file and revert its UCI-contents
qmp_config_revert() {

	local CONF=$1
	local SOURCE=$2

	if [ -z "$SOURCE" ]
	then
		SOURCE="qmp_config_revert"
	fi

	#Absolute path of file configuration
	local CONF_PATH=/etc/config

	if [ "$CONF" = "" ]
	then
		qmp_log_file "$SOURCE" "Reverting UCI config" "Nothing to set"
	else

		if [ -f $CONF_PATH/$CONF ]
		then
			cp $CONF_PATH/$CONF $CONF_PATH/$CONF.old
			qmp_log_file "$SOURCE" "Saved previous config in $CONF_PATH/$CONF.old" "Done"
		fi

		if uci revert $CONF &> /dev/null
		then
			qmp_log_file "$SOURCE" "Reverting UCI config '$CONF'" "Done"
		else
			qmp_log_file "$SOURCE" "Reverting UCI config '$CONF', returned '$(uci revert $CONF 2>&1)'" "Error"
		fi 

		echo "" > $CONF_PATH/$CONF
	fi
}

# Execute the commiting command of UCI
qmp_config_commit(){

	local CONF=$1
	local SOURCE=$2

	if [ -z "$SOURCE" ]
	then
		SOURCE="qmp_config_commit"
	fi

	if [ "$CONF" = "" ]
	then
		qmp_log_file "$SOURCE" "Comitting UCI" "Nothing to commit"
	else
		if uci commit $CONF &> /dev/null
		then
			qmp_log_file "$SOURCE" "Comitting UCI '$CONF'" "Done"
		else
			qmp_log_file "$SOURCE" "Comitting UCI '$CONF', returned '$(uci commit $CONF 2>&1)'" "Failed"
		fi

	fi

}

# Text colour control function returns text string colored or styled (ANSI terminals)
#qmp_styled_string() {

#	local STRING=$1
#	local STYLE=$2

#	case $STYLE in
#		"BLUE") printf "\033[1;34;48m%s\033[0m" "$STRING";;
#		"GREEN") printf "\033[1;32;48m%s\033[0m" "$STRING";;
#		"RED") printf "\033[1;31;48m%s\033[0m" "$STRING" ;;
#		"BOLD") printf "\033[1;30;48m%s\033[0m" "$STRING";;
#		"YELLOW") printf "\033[1;33;48m%s\033[0m" "$STRING";;
#		*) printf "$STRING"
#	esac
#}

# Send a formated logging message to standard output
qmp_log_stdout(){

	local SOURCE=$1
	local INSTANCE=$2
	local OUTCOME=$3

	if [ -z "$SOURCE" ]
	then
		SOURCE="qmp_log_stdout"
	fi

	if [ -z "$OUTCOME" ]
	then
		printf "%s: %s\n" "$SOURCE" "$INSTANCE"
	else
		printf "%s: %s -> %s\n" "$SOURCE" "$INSTANCE" "[$OUTCOME]"

	fi

}

# Send a message to syslog
qmp_log_file(){

	local SOURCE=$1
	local INSTANCE=$2
	local OUTCOME=$3

	if [ -z "$SOURCE" ]
	then
		SOURCE="qmp_log_file"
	fi

	local NODENAME="$(uname -n)"
	local DAYTIME="$(date +"%Y/%m/%d %T")"

	if [ -z "$OUTCOME" ]
	then
		printf "%s %s: %s: %s\n" "$DAYTIME" "$NODENAME" "$SOURCE" "$INSTANCE" >> $LOGFILE
	else
		printf "%s %s: %s: %s -> %s\n" "$DAYTIME" "$NODENAME" "$SOURCE" "$INSTANCE" "[$OUTCOME]" >> $LOGFILE

	fi

}

#Sends the standard logging message to all streams
qmp_log_all() {

	local SOURCE=$1
	local INSTANCE=$2
	local OUTCOME=$3

	if [ -z "$SOURCE" ]
	then
		SOURCE="qmp_log_all"
	fi

	qmp_log_file "$SOURCE" "$INSTANCE" "$OUTCOME"
	qmp_log_stdout "$SOURCE" "$INSTANCE" "$OUTCOME"

}

# Check whether the passed argument is defined in UCI config file
qmp_config_check() {

	local OPTION=$1

	if uci get $OPTION &> /dev/null
	then
		return 0
	fi

	return 1
}

#Provide the MAC of a supplied network device. Otherwise a default MAC addres is returned
qmp_get_dev_mac() {

	local DEV=$1

	#A convenient default MAC address
	local DEF_MAC="00:00:00:00:00:00"

	if ip addr show dev $DEV &> /dev/null
	then
		ip addr show dev $DEV | grep -m 1 "link/ether" | awk '{print $2}'
	else
		echo $DEF_MAC
	fi
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

      addr16=$( printf "%x" $(( $(( $ip1 * 0x100 )) + $ip2 )) )

      if [ -z "$ip4" ] ; then
        echo "Invalid 3 IPv6 address $addr_prefix" 1>&2
        return 1
      fi
      
      addr_in=$( printf "%x" $(( $(( $ip3 * 0x100 )) + $ip4 )) )$addr_in


    fi

    local prefix16
    if [ "$pos" -le "$mask" ] ; then

      if [ "$(( $pos + 16 ))" -le "$mask" ] ; then
	prefix16=$addr16
      else
	prefix16=$( printf "%x" $(( 0x$addr16 & 0xFFFF<<$(( $(( $pos + 16 )) - $mask )) )) )
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



#Get extented IPv6 address, from a given compact notation IPv6 prefix and mask
qmp_get_ip6_fast() {

	if ! [ -x /usr/bin/ipv6calc ] ; then
		qmp_get_ip6_slow $1
		return $?
	fi

	local SOURCE="qmp_get_ip6_fast"
	local ADDR_PREFIX="$1"
	local ADDR="$(echo $ADDR_PREFIX | awk -F'/' '{print $1}')"
	local MASK="$(echo $ADDR_PREFIX | awk -F'/' '{print $2}')"
	local DEF_ADDR="fdff::"
	local DEF_MASK="128"

	if [ -z "$ADDR" ]
	then
		#A default prefix is defined if none value is supplied
		ADDR=$DEF_ADDR
		qmp_log_file "$SOURCE" "Supplied prefix must have non-void value, prefix='$ADDR'" "Warning"
	fi

	if [ -z "$MASK" ] || [ "$(( $MASK % 16))" != "0" ]
	then
		#A default mask is defined if no value is supplied
		MASK=$DEF_MASK
		qmp_log_file "$SOURCE" "Supplied bitmask has a value that is null or non multiple of 16, new bitmask=$MASK" "Warning"
		#return 1
	fi

	if ipv6calc -q --in ipv6 $ADDR --showinfo -m &> /dev/null
	then
		local EXT_ADDR=$( ipv6calc -q  --in ipv6 $ADDR --showinfo -m | grep IPV6= | awk -F'=' '{print $2}' )
	else
		local EXT_ADDR=$( ipv6calc -q  --in ipv6 $DEF_ADDR --showinfo -m | grep IPV6= | awk -F'=' '{print $2}' )
		qmp_log_file "$SOURCE" "Supplied prefix '$ADDR/$MASK' is not valid" "Error"
		return 1
	fi

	if [ "$MASK" -ge "0" ] &&  [ "$MASK" -le "112" ]
	then
		echo "$( ipv6calc --in ipv6 $ADDR/$MASK -F --printprefix --out ipv6addr )::/$MASK"
	else
		echo "$( ipv6calc --in ipv6 $ADDR/$DEF_MASK -F --printprefix --out ipv6addr )"
	fi

}

#Calculate a complete ULA address from given components according to 48/48/32 bitscheme
qmp_calculate_ula96() {

	local PREFIX=$1 
	local MAC_ADDR=$2
	local SUFFIX=$3

	local SOURCE="qmp_calculate_ula96"

	#Check whether doubled-colon is present in PREFIX
	if echo $PREFIX |grep "::" &> /dev/null
	then
		PREFIX=$( echo $PREFIX | sed 's/::/:0:/g' )
	fi


	local MAC_ADDR1="$( echo $MAC_ADDR | awk -F':' '{print $1}' )"
	local MAC_ADDR2="$( echo $MAC_ADDR | awk -F':' '{print $2}' )"
	local MAC_ADDR3="$( echo $MAC_ADDR | awk -F':' '{print $3}' )"
	local MAC_ADDR4="$( echo $MAC_ADDR | awk -F':' '{print $4}' )"
	local MAC_ADDR5="$( echo $MAC_ADDR | awk -F':' '{print $5}' )"
	local MAC_ADDR6="$( echo $MAC_ADDR | awk -F':' '{print $6}' )"

	local IP6_SUBNETID48=`printf ":%x:%x:%x\n" $(( ( 0x$MAC_ADDR1 * 0x100 ) + 0x$MAC_ADDR2 )) $(( ( 0x$MAC_ADDR3 * 0x100 ) + 0x$MAC_ADDR4 )) $(( ( 0x$MAC_ADDR5 * 0x100 ) + 0x$MAC_ADDR6 )))`

	qmp_log_file "$SOURCE" "prefix='$PREFIX', subnetid='$IP6_SUBNETID48', suffix='$SUFFIX'" ""

	local IP6_ULA_ADDR=$( qmp_get_ip6_fast "${PREFIX}${IP6_SUBNETID48}${SUFFIX}/128" )

	if [ -z "$IP6_ULA_ADDR" ]
	then
		return 1
	fi

	echo $IP6_ULA_ADDR

}

#Build node id number
qmp_node_id() {

	local PRIMARY_DEV=$1

	local SOURCE="qmp_node_id"

	local NODE_ID

	if qmp_config_check ${QMP_CONFIG}.node.community_node_id
	then
		NODE_ID=$(uci get ${QMP_CONFIG}.node.community_node_id)
	else
		NODE_ID="4096"
	fi

	local NODE_PRJ

	if [ "$NODE_ID" -ge "0" ] && [ "$NODE_ID" -le "4095" ]
	then
		NODE_PRJ=$NODE_ID
		qmp_log_file "$SOURCE" "Builded node-id='$NODE_PRJ' from '${QMP_CONFIG}.node.community_node_id'" ""
	else
		local MAC_ADDR=$(qmp_get_dev_mac $PRIMARY_DEV)
		local MAC_ADDR5="$( echo $MAC_ADDR | awk -F':' '{print $5}' )"
		local MAC_ADDR6="$( echo $MAC_ADDR | awk -F':' '{print $6}' )"
		NODE_PRJ=$(( 0x$MAC_ADDR6 + ( 0x$MAC_ADDR5 & 0xf ) * 0x100  ))
		qmp_log_file "$SOURCE" "Builded node-id='$NODE_PRJ' from $PRIMARY_DEV MAC address" ""
	fi

	echo $NODE_PRJ

}


#Calculate the community node id projection onto an IPv6 address byte-group (16 bits = 12 node-id-bits + 4 protocol-id-bits) from the canonical protocol's names
qmp_node_proj() {

	local PRIMARY_DEV=$1
	local PROT_CNAME=$2

	local SOURCE="qmp_node_proj"

	local PROTOCOL_ID

	case $PROT_CNAME in
		"$OLSR6_CNAME") PROTOCOL_ID="1";;
		"$BMX6_CNAME") PROTOCOL_ID="2";;
		#Add more protocol values between 1 and 15 (4 bits)
		*) PROTOCOL_ID="0";;
	esac

	local NODE_PRJ=$(( 0x$(printf "%x" $(qmp_node_id $PRIMARY_DEV)) * 0x10 ))

	if [ "$PROTOCOL_ID" -gt "0" ] && [ "$PROTOCOL_ID" -le "15" ]
	then
		NODE_PRJ=$(( $NODE_PRJ + $PROTOCOL_ID ))
		printf "%x" $NODE_PRJ
	else
		printf "%x" $NODE_PRJ
	fi

	qmp_log_file "$SOURCE" "Byte-group-projection='$(printf "0x%x" $NODE_PRJ)', protocol='$PROT_CNAME'"

}

#Calculate a complete global address from given components according to 48/16/64 bitscheme
qmp_calculate_global64() {

	local PREFIX=$1 
	local NODE=$2
	local SUFFIX=$3

	local SOURCE="qmp_calculate_global64"

	#Only file output stream is allowed in this function, otherwise its output interferes with proper returned value

	#Check whether doubled-colon is present in PREFIX
	if echo $PREFIX |grep "::" &> /dev/null
	then
		PREFIX=$( echo $PREFIX | sed 's/::/:0:/g' )
	fi

	local IP6_SUBNETID16

	if printf ":%x\n" 0x$NODE &> /dev/null
	then
		IP6_SUBNETID16=`printf ":%x\n" 0x$NODE`
	else
		qmp_log_file "$SOURCE" "Incorrect node value, printf='`printf ":%x\n" 0x$NODE 2>&1`'" "Error"
		return 1
	fi

	qmp_log_file "$SOURCE" "prefix='$PREFIX', subnetid='$IP6_SUBNETID16', suffix='$SUFFIX'"
	local IP6_GLOB_ADDR=$( qmp_get_ip6_fast "${PREFIX}${IP6_SUBNETID16}${SUFFIX}/128" )

	if [ -z "$IP6_GLOB_ADDR" ]
	then
		return 1
	fi

	echo $IP6_GLOB_ADDR

}

#Compose a complete ULA address from given components: ULA prefix, network device, suffix and mask
qmp_get_ula96() {

	local PREFIX=$1
	local DEV_MAC=$2
	local SUFFIX=$3
	local MASK=$4

	local MAC_ADDR=$( qmp_get_dev_mac $DEV_MAC )
	local IP6_ULA_ADDR=$( qmp_calculate_ula96 $PREFIX $MAC_ADDR $SUFFIX )

	echo "$IP6_ULA_ADDR/$MASK"
}



qmp_get_global64() {

	local PREFIX=$1
	local NODE=$2
	local SUFFIX=$3
	local MASK=$4

	local IP6_GLOB_ADDR=$( qmp_calculate_global64 $PREFIX $NODE $SUFFIX )

	echo "$IP6_GLOB_ADDR/$MASK"
}


#The first device on the list CONFIG.interfaces.mesh_devices is the primary one
qmp_get_primary_dev() {

	local CONFIG=$1
	local SOURCE="qmp_get_primary_dev"

	if qmp_config_check $CONFIG.interfaces.mesh_devices
	then
		local PRIMARY_MESH_DEV="$(uci get $CONFIG.interfaces.mesh_devices | awk '{print $1}')"
	else
		#Only file output stream is allowed in this function, otherwise its output interferes with proper returned value
		qmp_log_file "$SOURCE" "No primary mesh iface, $CONFIG.interfaces.mesh_devices = void" "Fail"
	fi

	echo $PRIMARY_MESH_DEV

}


qmp_configure_network() {

	local SOURCE="qmp_configure_network"

	qmp_log_all "$SOURCE" "General network configuration started..." ""

	qmp_config_revert "$BASE_CONFIG" "$SOURCE"

	#If there is 'configure_switch' field in qmp file, configure it! PLEASE REVIEW IT!!!!!

	if qmp_config_check ${QMP_CONFIG}.interfaces.configure_switch
	then

	qmp_log_all "$SOURCE" "<<<< Switch configuration >>>>" ""

		local SWITCH_DEVICE="$(uci get ${QMP_CONFIG}.interfaces.configure_switch)"

		qmp_set_option $BASE_CONFIG.$SWITCH_DEVICE "switch" "$SOURCE"
		qmp_set_option $BASE_CONFIG.$SWITCH_DEVICE.enable "1" "$SOURCE"
		qmp_set_option $BASE_CONFIG.$SWITCH_DEVICE.enable_vlan "1" "$SOURCE"
		qmp_set_option $BASE_CONFIG.$SWITCH_DEVICE.reset "1" "$SOURCE"

		qmp_set_option $BASE_CONFIG.lan_ports "switch_vlan" "$SOURCE"
		qmp_set_option $BASE_CONFIG.lan_ports.vlan "1" "$SOURCE"
		qmp_set_option $BASE_CONFIG.lan_ports.device "$switch_device" "$SOURCE"
		qmp_set_option $BASE_CONFIG.lan_ports.ports "0 1 5t" "$SOURCE"

		qmp_set_option $BASE_CONFIG.wan_ports "switch_vlan" "$SOURCE"
		qmp_set_option $BASE_CONFIG.wan_ports.vlan "2" "$SOURCE"
		qmp_set_option $BASE_CONFIG.wan_ports.device "$switch_device" "$SOURCE"
		qmp_set_option $BASE_CONFIG.wan_ports.ports "4 5t" "$SOURCE"

		if qmp_config_check ${QMP_CONFIG}.interfaces.mesh_devices && qmp_config_check ${QMP_CONFIG}.networks.mesh_protocol_vids && qmp_config_check ${QMP_CONFIG}.networks.mesh_vid_offset
		then

			for PROT_DESCR in $(uci get ${QMP_CONFIG}.networks.mesh_protocol_vids)
			do

				local VID_SUFFIX="$(echo $PROT_DESCR | awk -F':' '{print $2}')"
				local VID_OFFSET="$(uci get ${QMP_CONFIG}.networks.mesh_vid_offset)"
				local VID="$(( $VID_OFFSET + $VID_SUFFIX ))"
				local MESH_PORTS="mesh_ports_vid${VID}"

				qmp_set_option $BASE_CONFIG.$MESH_PORTS "switch_vlan" "$SOURCE"
				qmp_set_option $BASE_CONFIG.$MESH_PORTS.vlan "$vid" "$SOURCE"
				qmp_set_option $BASE_CONFIG.$MESH_PORTS.device "$switch_device" "$SOURCE"
				qmp_set_option $BASE_CONFIG.$MESH_PORTS.ports "2t 3t 5t" "$SOURCE"

			done
		fi
	fi

	qmp_log_all "$SOURCE" "<<<< Loopback interface configuration >>>>" ""

	qmp_set_option $BASE_CONFIG.loopback "interface" "$SOURCE"
	qmp_set_option $BASE_CONFIG.loopback.ifname "lo" "$SOURCE"
	qmp_set_option $BASE_CONFIG.loopback.proto "static" "$SOURCE"
	qmp_set_option $BASE_CONFIG.loopback.ipaddr "127.0.0.1" "$SOURCE"
	qmp_set_option $BASE_CONFIG.loopback.netmask "255.0.0.0" "$SOURCE"

	#The declared wan device is configured with dhcp protocol
	if qmp_config_check ${QMP_CONFIG}.interfaces.wan_device
	then
		qmp_log_all "$SOURCE" "<<<< Wan interface configuration >>>>" ""
		qmp_set_option $BASE_CONFIG.wan "interface" "$SOURCE"
		qmp_set_option $BASE_CONFIG.wan.ifname "$(uci get ${QMP_CONFIG}.interfaces.wan_device)" "$SOURCE"
		qmp_set_option $BASE_CONFIG.wan.proto "dhcp" "$SOURCE"
	fi

	#Setting niit4to6 and niit6to4 tunnel interfaces configuration
	qmp_log_all "$SOURCE" "<<<< niit6to4 tunnel interface configuration >>>>" ""
	qmp_set_option $BASE_CONFIG.niit4to6 "interface" "$SOURCE"
	qmp_set_option $BASE_CONFIG.niit4to6.proto "none" "$SOURCE"
	qmp_set_option $BASE_CONFIG.niit4to6.ifname "niit4to6" "$SOURCE"

	qmp_set_option $BASE_CONFIG.niit6to4 "interface" "$SOURCE"
	qmp_set_option $BASE_CONFIG.niit6to4.proto "none" "$SOURCE"
	qmp_set_option $BASE_CONFIG.niit6to4.ifname "niit6to4" "$SOURCE"

	#Get the primary mesh device
	local PRIMARY_MESH_DEV="$(qmp_get_primary_dev $QMP_CONFIG $SOURCE)"

	#Configuration of LAN devices defined in ${QMP_CONFIG} with default IPv4 static address
	if qmp_config_check ${QMP_CONFIG}.interfaces.lan_devices
	then
		qmp_log_all "$SOURCE" "<<<< Lan interfaces configuration >>>>" ""
		#ONLY ONE DEVICE IS CONSIDERED? Ali2D3 has 3 ethN...
		qmp_set_option $BASE_CONFIG.lan "interface" "$SOURCE"
		qmp_set_option $BASE_CONFIG.lan.ifname "$(uci get ${QMP_CONFIG}.interfaces.lan_devices)" "$SOURCE"
#    qmp_set_option $BASE_CONFIG.lan.type="bridge"
		qmp_set_option $BASE_CONFIG.lan.proto "static" "$SOURCE"
		qmp_set_option $BASE_CONFIG.lan.ipaddr "192.168.31.6" "$SOURCE"
		qmp_set_option $BASE_CONFIG.lan.netmask "255.255.255.0" "$SOURCE"

		#Configure all the devices defined like mesh device and assign them unicast global adresses and IPv4 addreses
		if qmp_config_check ${QMP_CONFIG}.interfaces.mesh_devices && qmp_config_check ${QMP_CONFIG}.networks.mesh_protocol_vids
		then
			qmp_log_all "$SOURCE" "<<<< Mesh interfaces configuration >>>>" ""

			for PROT_DESCR in $(uci get ${QMP_CONFIG}.networks.mesh_protocol_vids); do

			local PROTOCOL_NAME="$(echo $PROT_DESCR | awk -F':' '{print $1}')"
			local NIIT_DEV="niit4to6_${PROTOCOL_NAME}"

			qmp_set_option $BASE_CONFIG.$NIIT_DEV "alias" "$SOURCE"
			qmp_set_option $BASE_CONFIG.$NIIT_DEV.interface "niit4to6" "$SOURCE"
			qmp_set_option $BASE_CONFIG.$NIIT_DEV.proto "static" "$SOURCE"

			local NODE_PROJ="$(qmp_node_proj $PRIMARY_MESH_DEV $PROTOCOL_NAME)"

				if qmp_config_check ${QMP_CONFIG}.node.global_prefix48
				then
					local IP6_GLOBAL_PREFIX48="$(uci get ${QMP_CONFIG}.node.global_prefix48)"
					qmp_set_option $BASE_CONFIG.$NIIT_DEV.ip6addr "$(qmp_get_global64 $IP6_GLOBAL_PREFIX48 $NODE_PROJ ::1 64)" "$SOURCE"
				fi

				if qmp_config_check ${QMP_CONFIG}.networks.${PROTOCOL_NAME}_ipv4_address && qmp_config_check ${QMP_CONFIG}.networks.${PROTOCOL_NAME}_ipv4_netmask
				then
					qmp_set_option $BASE_CONFIG.$NIIT_DEV.ipaddr "$(uci get ${QMP_CONFIG}.networks.${PROTOCOL_NAME}_ipv4_address)" "$SOURCE"
					qmp_set_option $BASE_CONFIG.$NIIT_DEV.netmask "$(uci get ${QMP_CONFIG}.networks.${PROTOCOL_NAME}_ipv4_netmask)" "$SOURCE"

				elif qmp_config_check ${QMP_CONFIG}.networks.${PROTOCOL_NAME}_ipv4_prefix24
				then
					local IP4_SUBNETID16="$(( 0x$NODE_PROJ / 0x100 )).$(( 0x$NODE_PROJ % 0x100 ))"
					qmp_set_option $BASE_CONFIG.$NIIT_DEV.ipaddr "$(uci get ${QMP_CONFIG}.networks.${PROTOCOL_NAME}_ipv4_prefix24).$IP4_SUBNETID16" "$SOURCE"
					qmp_set_option $BASE_CONFIG.$NIIT_DEV.netmask "255.255.255.255" "$SOURCE"
				fi

			done
		fi
	fi

	#Create new VLAN interfaces for each present protocol
	local COUNTER=1

	if qmp_config_check ${QMP_CONFIG}.interfaces.mesh_devices && qmp_config_check ${QMP_CONFIG}.networks.mesh_protocol_vids
	then

	local VID
	local BASE_VID

		qmp_log_all "$SOURCE" "<<<< VLAN interfaces configuration >>>>" ""

		if qmp_config_check ${QMP_CONFIG}.networks.mesh_vid_offset
		then
			BASE_VID="$(uci get ${QMP_CONFIG}.networks.mesh_vid_offset)"
		else
			BASE_VID="1"
		fi

		for MESH_DEV in $(uci get ${QMP_CONFIG}.interfaces.mesh_devices); do

		VID=$BASE_VID

			for PROTOCOL_DESCR in $(uci get ${QMP_CONFIG}.networks.mesh_protocol_vids); do

				local PROTOCOL_NAME="$(echo $PROTOCOL_DESCR | awk -F':' '{print $1}')"
				local VID_DESCR="$(echo $PROTOCOL_DESCR | awk -F':' '{print $2}')"

				#According to IEEE 802.1Q only VID-values between 1 and 4094 are allowed 
				if [ "$VID_DESCR" -ge "1" ] && [ "$VID_DESCR" -le "4094" ]
				then
					VID=$VID_DESCR
				fi

				#Beginning of interfaces configuration
				local MESH="mesh_${PROTOCOL_NAME}_${COUNTER}"
				local IP6_IFACEID32=":0:$(qmp_node_proj $PRIMARY_MESH_DEV $PROTOCOL_NAME)"

				if qmp_config_check ${QMP_CONFIG}.networks.${PROTOCOL_NAME}_ula_prefix48
				then

					qmp_set_option $BASE_CONFIG.$MESH "interface" "$SOURCE"
					qmp_set_option $BASE_CONFIG.$MESH.ifname "$MESH_DEV.$VID" "$SOURCE"
					qmp_set_option $BASE_CONFIG.$MESH.proto "static" "$SOURCE"
					qmp_set_option $BASE_CONFIG.$MESH.ip6addr "$(qmp_get_ula96 $(uci get ${QMP_CONFIG}.networks.${PROTOCOL_NAME}_ula_prefix48) $MESH_DEV $IP6_IFACEID32 128)" "$SOURCE"
				fi
				#End of interfaces configuration
				
				VID=$(( $VID + 1 ))

			done

			COUNTER=$(( $COUNTER + 1 ))
		done
	fi

	qmp_config_commit "$BASE_CONFIG" "$SOURCE"

}



qmp_configure_bmx6() {

	local SOURCE="qmp_configure_bmx6"

	qmp_log_all "$SOURCE" "<<<< bmx6 daemon configuration >>>>" ""
	qmp_config_revert "$BMX6_CONFIG" "$SOURCE"

	qmp_set_option "$BMX6_CONFIG.general" "$BMX6_CNAME" "$SOURCE"
	#qmp_set_option "$BMX6_CONFIG.general.ula_prefix" "$(uci get ${QMP_CONFIG}.networks.bmx6_ula_prefix48)::/48" "$SOURCE"
	qmp_set_option "$BMX6_CONFIG.general.globalPrefix" "$(uci get ${QMP_CONFIG}.networks.bmx6_ula_prefix48)::/48" "$SOURCE"

	qmp_set_option "$BMX6_CONFIG.bmx6_config_plugin" "plugin" "$SOURCE"
	qmp_set_option "$BMX6_CONFIG.bmx6_config_plugin.plugin" "bmx6_config.so" "$SOURCE"
	qmp_set_option "$BMX6_CONFIG.bmx6_json_plugin" "plugin" "$SOURCE"
	qmp_set_option "$BMX6_CONFIG.bmx6_json_plugin.plugin" "bmx6_json.so" "$SOURCE"

	qmp_set_option "$BMX6_CONFIG.ipVersion" "ipVersion" "$SOURCE"
	qmp_set_option "$BMX6_CONFIG.ipVersion.ipVersion" "6" "$SOURCE"
	qmp_set_option "$BMX6_CONFIG.ipVersion.throwRules" "0" "$SOURCE"


	local PRIMARY_MESH_DEV="$(qmp_get_primary_dev $QMP_CONFIG "$SOURCE")"
	local NODE_PROJ="$(qmp_node_proj $PRIMARY_MESH_DEV $BMX6_CNAME)"
	qmp_log_all "$SOURCE" "Primary mesh devide='$PRIMARY_MESH_DEV'"

	#Create new VLAN interfaces for bmx6
	local COUNTER=1

	if qmp_config_check ${QMP_CONFIG}.interfaces.mesh_devices && qmp_config_check ${QMP_CONFIG}.networks.mesh_protocol_vids
	then

	local VID
	local BASE_VID

		if qmp_config_check ${QMP_CONFIG}.networks.mesh_vid_offset
		then
			BASE_VID="$(uci get ${QMP_CONFIG}.networks.mesh_vid_offset)"
		else
			BASE_VID="1"
		fi

		for MESH_DEV in $(uci get ${QMP_CONFIG}.interfaces.mesh_devices); do

		VID=$BASE_VID

			for PROTOCOL_DESCR in $(uci get ${QMP_CONFIG}.networks.mesh_protocol_vids); do

				local PROTOCOL_NAME="$(echo $PROTOCOL_DESCR | awk -F':' '{print $1}')"
				
				if [ "$PROTOCOL_NAME" = "$BMX6_CNAME" ]
				then
				
					local VID_DESCR="$(echo $PROTOCOL_DESCR | awk -F':' '{print $2}')"

					#According to IEEE 802.1Q only VID-values between 1 and 4094 are allowed 
					if [ "$VID_DESCR" -ge "1" ] && [ "$VID_DESCR" -le "4094" ]
					then
						VID=$VID_DESCR
					fi

					#Beginning of interfaces configuration
					local IFNAME="$MESH_DEV.$VID"

					qmp_set_option "$BMX6_CONFIG.mesh_$COUNTER" "dev" "$SOURCE"
					qmp_set_option "$BMX6_CONFIG.mesh_$COUNTER.dev" "$IFNAME" "$SOURCE"

					if qmp_config_check ${QMP_CONFIG}.networks.bmx6_ipv4_address
					then
						qmp_set_option "$BMX6_CONFIG.general.niitSource" "$(uci get ${QMP_CONFIG}.networks.bmx6_ipv4_address)" "$SOURCE"
						
					elif qmp_config_check ${QMP_CONFIG}.networks.bmx6_ipv4_prefix24
					then
						local IP4_SUBNETID16="$(( 0x$NODE_PROJ / 0x100 )).$(( 0x$NODE_PROJ % 0x100 ))"
						qmp_set_option "$BMX6_CONFIG.general.niitSource" "$(uci get ${QMP_CONFIG}.networks.bmx6_ipv4_prefix24).$IP4_SUBNETID16" "$SOURCE"
						
					fi
					#End of interfaces configuration

				fi

				VID=$(( $VID + 1 ))
			done

			COUNTER=$(( $COUNTER + 1 ))
		done
	fi


	if qmp_config_check ${QMP_CONFIG}.node.global_prefix48
	then
		qmp_set_option "$BMX6_CONFIG.ripe" "hna" "$SOURCE"
		qmp_set_option "$BMX6_CONFIG.ripe.hna" "$(uci get ${QMP_CONFIG}.node.global_prefix48):$NODE_PROJ:0:0:0:0/64" "$SOURCE"

	fi

	if qmp_config_check ${QMP_CONFIG}.networks.niit_prefix96
	then
	
		if qmp_config_check ${QMP_CONFIG}.networks.bmx6_ipv4_address && qmp_config_check ${QMP_CONFIG}.networks.bmx6_ipv4_netmask && qmp_config_check ${QMP_CONFIG}.networks.bmx6_6to4_netmask
		then
			local NIIT6TO4_ADDR="$(qmp_get_ip6_fast $(uci get ${QMP_CONFIG}.networks.niit_prefix96):$(uci get ${QMP_CONFIG}.networks.bmx6_ipv4_address)/$(uci get ${QMP_CONFIG}.networks.bmx6_6to4_netmask))"
			qmp_set_option "$BMX6_CONFIG.niit6to4" "unicast_hna" "$SOURCE"
			qmp_set_option "$BMX6_CONFIG.niit6to4.hna" "$NIIT6TO4_ADDR/$(uci get ${QMP_CONFIG}.networks.bmx6_6to4_netmask)" "$SOURCE"

		elif qmp_config_check ${QMP_CONFIG}.networks.bmx6_ipv4_prefix24
		then
			local NIIT6TO4_ADDR="$(uci get ${QMP_CONFIG}.networks.niit_prefix96):$(uci get ${QMP_CONFIG}.networks.bmx6_ipv4_prefix24).$IP4_SUBNETID16"
			qmp_set_option "$BMX6_CONFIG.niit6to4" "unicast_hna" "$SOURCE"
			qmp_set_option "$BMX6_CONFIG.niit6to4.hna" "$NIIT6TO4_ADDR/128" "$SOURCE"

		fi
	fi

	qmp_config_commit "$BMX6_CONFIG" "$SOURCE"
#  /etc/init.d/$BMX6_CONFIG restart
}

qmp_configure_olsr6() {

	local SOURCE="qmp_configure_olsr6"

	qmp_log_all "$SOURCE" "<<<< olsr6 daemon configuration >>>>" ""

	local CONF_FILE="/etc/olsrd.conf"

	qmp_config_revert "$OLSR6_CONFIG" "$SOURCE"

	qmp_add_option "$OLSR6_CONFIG" "olsrd" "$SOURCE"
	qmp_set_option "$OLSR6_CONFIG.@olsrd[0].config_file" "$CONF_FILE" "$SOURCE"

	qmp_config_commit "$OLSR6_CONFIG" "$SOURCE"


cat <<EOF > $CONF_FILE
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

	local PRIMARY_MESH_DEV="$(qmp_get_primary_dev ${QMP_CONFIG} "$SOURCE")"
	local NODE_PROJ="$(qmp_node_proj $PRIMARY_MESH_DEV $OLSR6_CNAME)"

	#Declare VLAN interfaces for olsrd.conf
	local COUNTER=1

	if qmp_config_check ${QMP_CONFIG}.interfaces.mesh_devices && qmp_config_check ${QMP_CONFIG}.networks.mesh_protocol_vids
	then

	local VID
	local BASE_VID

		if qmp_config_check ${QMP_CONFIG}.networks.mesh_vid_offset
		then
			BASE_VID="$(uci get ${QMP_CONFIG}.networks.mesh_vid_offset)"
		else
			BASE_VID="1"
		fi

		for MESH_DEV in $(uci get ${QMP_CONFIG}.interfaces.mesh_devices); do

		VID=$BASE_VID

			for PROTOCOL_DESCR in $(uci get ${QMP_CONFIG}.networks.mesh_protocol_vids); do

				local PROTOCOL_NAME="$(echo $PROTOCOL_DESCR | awk -F':' '{print $1}')"
				
				if [ "$PROTOCOL_NAME" = "$OLSR6_CNAME" ]
				then
				
					local VID_DESCR="$(echo $PROTOCOL_DESCR | awk -F':' '{print $2}')"

					#According to IEEE 802.1Q only VID-values between 1 and 4094 are allowed 
					if [ "$VID_DESCR" -ge "1" ] && [ "$VID_DESCR" -le "4094" ]
					then
						VID=$VID_DESCR
					fi

					#Beginning of interfaces configuration
					local IFNAME="$MESH_DEV.$VID"

					local MODE="$(if echo $MESH_DEV | grep -v ath | grep -v wlan > /dev/null 2>&1; then echo ether; else echo mesh; fi)"
					local MESH="mesh_${PROTOCOL_NAME}_${COUNTER}"
					qmp_log_all "$SOURCE" "Selected mode '$MODE'"
					local IP6_IFACEID32=":0:$NODE_PROJ"
					local IP6_ADDR="$( qmp_get_ip6_fast $(qmp_get_ula96 $(uci get ${QMP_CONFIG}.networks.${PROTOCOL_NAME}_ula_prefix48) $MESH_DEV $IP6_IFACEID32 128) )"

cat <<EOF >> $CONF_FILE

Interface "$IFNAME"
{
    Mode                "$MODE"
    IPv6Multicast       FF0E::1
    IPv6Src             $IP6_ADDR
}

EOF
					#End of interfaces configuration
				fi

					VID=$(( $VID + 1 ))
			done

			COUNTER=$(( $COUNTER + 1 ))
		done
	fi



	if qmp_config_check ${QMP_CONFIG}.node.global_prefix48
	then

cat <<EOF >> $CONF_FILE
Hna6
{
$(uci get ${QMP_CONFIG}.node.global_prefix48):${NODE_PROJ}:0:0:0:0 64
}

EOF
	fi

	if qmp_config_check ${QMP_CONFIG}.networks.niit_prefix96
	then

		if qmp_config_check ${QMP_CONFIG}.networks.olsr6_ipv4_address && qmp_config_check ${QMP_CONFIG}.networks.olsr6_ipv4_netmask && qmp_config_check ${QMP_CONFIG}.networks.olsr6_6to4_netmask
		then
			local IP4_ADDR=$(uci get ${QMP_CONFIG}.networks.olsr6_ipv4_address)
			#local IP6_IFACEID96="$(echo $(ipv6calc -q --action conv6to4 --in ipv4 $IP4_ADDR) | awk -F':' '{print $2}')"
			#local IP6_IFACEID112="$(echo $(ipv6calc -q --action conv6to4 --in ipv4 $IP4_ADDR) | awk -F':' '{print $3}')"
cat <<EOF >> $CONF_FILE
Hna6
{
$(uci get ${QMP_CONFIG}.networks.niit_prefix96):$IP6_ADDR $(uci get ${QMP_CONFIG}.networks.olsr6_6to4_netmask)
}

EOF

		elif qmp_config_check ${QMP_CONFIG}.networks.olsr6_ipv4_prefix24
		then
			local IP4_SUBNETID16=$(uci get ${QMP_CONFIG}.networks.olsr6_ipv4_prefix24)
			local IP6_IFACEID96="$(echo $(ipv6calc -q --action conv6to4 --in ipv4 ${IP4_SUBNETID16}.$(( 0x$NODE_PROJ / 0x100 )).$(( 0x$NODE_PROJ % 0x100 ))) | awk -F':' '{print $2}'):$(echo $(ipv6calc -q --action conv6to4 --in ipv4 ${IP4_SUBNETID16}.$(( 0x$NODE_PROJ / 0x100 )).$(( 0x$NODE_PROJ % 0x100 ))) | awk -F':' '{print $3}')"

cat <<EOF >> $CONF_FILE
Hna6
{
$(uci get ${QMP_CONFIG}.networks.niit_prefix96):$IP6_IFACEID96 128
}

EOF
		fi
	fi
#  /etc/init.d/$OLSR6_CONFIG restart
}


qmp_configure_olsr6_uci_unused() {

  local OLSR6_UCI_CONFIG="olsrd_uci"

  qmp_config_revert "$OLSR6_UCI_CONFIG" "$SOURCE"


  uci set $OLSR6_UCI_CONFIG.networks="olsrd"
  uci set $OLSR6_UCI_CONFIG.networks.IpVersion="6"

  uci set $OLSR6_UCI_CONFIG.arprefresh="LoadPlugin"
  uci set $OLSR6_UCI_CONFIG.arprefresh.library="olsrd_arprefresh.so.0.1"

  uci set $OLSR6_UCI_CONFIG.httpinfo="LoadPlugin"
  uci set $OLSR6_UCI_CONFIG.httpinfo.library="olsrd_httpinfo.so.0.1"
  uci set $OLSR6_UCI_CONFIG.httpinfo.port="1978"
  uci add_list $OLSR6_UCI_CONFIG.httpinfo.Net="0::/0"

  uci set $OLSR6_UCI_CONFIG.nameservice="LoadPlugin"
  uci set $OLSR6_UCI_CONFIG.nameservice.library="olsrd_nameservice.so.0.3"

  uci set $OLSR6_UCI_CONFIG.txtinfo="LoadPlugin"
  uci set $OLSR6_UCI_CONFIG.txtinfo.library="olsrd_txtinfo.so.0.1"
  uci set $OLSR6_UCI_CONFIG.txtinfo.accept="0::"

  if qmp_config_check ${QMP_CONFIG}.interfaces.mesh_devices && qmp_config_check ${QMP_CONFIG}.networks.mesh_protocol_vids && qmp_config_check ${QMP_CONFIG}.networks.mesh_vid_offset; then

    local COUNTER=1
    local interface_list=""

    for MESH_DEV in $(uci get ${QMP_CONFIG}.interfaces.mesh_devices); do 
       for protocol_vid in $(uci get ${QMP_CONFIG}.networks.mesh_protocol_vids); do

         local protocol_name="$(echo $protocol_vid | awk -F':' '{print $1}')"

         echo "qmp_configure_olsr6 dev=$MESH_DEV protocol_vid=$protocol_vid protocol_name=$protocol_name"

         if [ "$protocol_name" = "olsr6" ] ; then

            local vid_suffix="$(echo $protocol_vid | awk -F':' '{print $2}')"
            local vid_offset="$(uci get ${QMP_CONFIG}.networks.mesh_vid_offset)"
	    local interface="olsr6_${COUNTER}"
	    local ifname="$MESH_DEV.$(( $vid_offset + $vid_suffix ))"

            echo "adding ifname=$ifname interface=$interface"

            interface_list="$interface_list $interface"

         fi

       done
    done
 
    uci set $OLSR6_UCI_CONFIG.interface="Interface"
    uci add_list $OLSR6_UCI_CONFIG.interface.interface="$interface_list"

  fi
  
  uci commit $OLSR6_UCI_CONFIG
#  /etc/init.d/$OLSR6_UCI_CONFIG restart
}


qmp_configure_system() {

	local PRIMARY_MESH_DEV="$(qmp_get_primary_dev ${QMP_CONFIG} "$SOURCE")"
	local NODE_ID="$(qmp_node_id $PRIMARY_MESH_DEV)"

	local SOURCE="qmp_configure_system"

	qmp_log_all "$SOURCE" "<<<< System configuration >>>>" ""
	qmp_set_option "system.@system[0].hostname" "qmp$NODE_ID" "$SOURCE"
	qmp_config_commit "system" "$SOURCE"

	#Enable IPv6 in httpd
	qmp_set_option "uhttpd.main.listen_http" "80" "$SOURCE"
	qmp_set_option "uhttpd.main.listen_https" "443" "$SOURCE"
	qmp_config_commit "uhttpd" "$SOURCE"

	qmp_log_all "$SOURCE" "Restarting httpd" "Initiated"
	/etc/init.d/uhttpd restart 2>&1 >> $LOGFILE
	qmp_log_all "$SOURCE" "Restarting httpd" "Finished"
}




qmp_configure() {

	qmp_configure_network
	qmp_configure_bmx6
	qmp_configure_olsr6
	qmp_configure_system

}

