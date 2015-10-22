#!/bin/sh
#    Copyright (C) 2015 Quick Mesh Project
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

QMP_PATH="/etc/qmp"

[ -z "$SOURCE_COMMON" ] && . $QMP_PATH/qmp_common.sh
#[ -z "$SOURCE_FUNCTIONS" ] && . $QMP_PATH/qmp_functions.sh

QMP_VERSION="$QMP_PATH/qmp.version"

[ -z $ONECLICK_CGI ] && ONECLICK_CGI=0
ONECLICK_FILE="/tmp/guifi_oneclick"
ONECLICK_PATTERN="qMp Guifi-oneclick"
ONECLICK_URL="/view/unsolclic"
ONECLICK_URL_BASE="http://guifi.net/guifi/device/"
ONECLICK_VARS="nodename latitude longitude devname devmodel ipv4 netmask zoneid"


get_url() {
	echo "Getting oneclick config:"

	[ -z $1 ] && {
		[ $ONECLICK_CGI -eq 1 ] && { echo "ERROR: No URL specified."; exit 1; } ||
		qmp_error "No URL specified. USE: '$0 get_url [${ONECLICK_URL_BASE}#####/] [FILE]'"
	} || {
                # TEMPORARY SOLUTION WHILE NO HTTPS SUPPORT FOR WGET                      
                echo $1 | grep -q "^https://" 2>/dev/null                                          
                [ $? -ne 0 ] || {                                                                             
                        [ $ONECLICK_CGI -eq 1 ] && { echo "ERROR: HTTPS URLs not supported yet."; exit 1; } ||
                        qmp_error "HTTPS URLs not supported yet."                         
                }
		echo $1 | grep -q "^http://" 2>/dev/null
		## TO DO CHECK IF ID OR URL IS GIVEN
		[ $? -ne 0 ] && {
			[ $ONECLICK_CGI -eq 1 ] && { echo "ERROR: Wrong URL specified."; exit 1; } ||
			qmp_error "Wrong URL specified. USE: '$0 get_url [${ONECLICK_URL_BASE}#####/] [FILE]'"
		}
	}	
	[ -z $2 ] && {
		[ $ONECLICK_CGI -eq 1 ] && { echo "ERROR: No temporary file specified."; exit 1; } ||
		qmp_error "No temporary file specified. USE: '$0 get_url [${ONECLICK_URL_BASE}#####/] [FILE]'"
	}

	# CHECK IF UNSOLCLIC OR DEVICE URL GIVEN
	local oneclick_url
	echo $1 | grep -q "/view/unsolclic$" 2>/dev/null
	[ $? -ne 0 ] && oneclick_url=$1$ONECLICK_URL || oneclick_url=$1

	wget -q $oneclick_url -O $2 2>/dev/null	
	[ $? -ne 0 ] && rm -f $file && {
		[ $ONECLICK_CGI -eq 1 ] && { echo "ERROR: Error downloading $oneclick_url"; exit 1; } ||
		qmp_error "Error downloading $oneclick_url"
	}
	
	# REMOVING "<br />" (to change output format edit guifi·net drupal module unsolclic file guifi/firmware/qmp.inc.php)
	sed -i 's/^<br \/>//g' $2

	echo "Done!"
	return 0
}

check() {
	echo "Checking oneclick config:"

	[ -z $1 ] && {
		[ $ONECLICK_CGI -eq 1 ] && { echo "ERROR: No file given."; exit 1; } ||
		qmp_error "No file given. USE: $0 check [FILE] "
	}
	[ ! -f $1 ] && {
		[ $ONECLICK_CGI -eq 1 ] && { echo "ERROR: File $1 not found."; exit 1; } ||
		qmp_error "File $1 not found."
	}

	# CHECK IF VALID UNSOLCLIC CONFIG
	grep -q "$ONECLICK_PATTERN" $1 2>/dev/null
	[ $? -ne 0 ] && {
		[ $ONECLICK_CGI -eq 1 ] && { echo "ERROR: Not valid unsolclic file. Check file or URL."; exit 1; } ||
		qmp_error "Not valid unsolclic file. Check file or URL."
	} 
	
	# CHECK IF HAS MESH RADIO
	local meshradio=`grep "meshradio" $1 | awk -F "=" '{print $2}' | tr -d "'"`
	[ "$meshradio" == "no" ] && {
		[ $ONECLICK_CGI -eq 1 ] && { echo "ERROR: No Mesh radio found. Revise your device configuration in the guifi.net website."; exit 1; } ||
		qmp_error "No Mesh radio found. Revise your device configuration in the guifi.net website."
	}
	
	echo "Done!"
	return 0
}

print() {
	echo "Showing variables:"
	[ -z $1 ] && {
		[ $ONECLICK_CGI -eq 1 ] && { echo "ERROR: No file given"; exit 1; } || 
		qmp_error "No file given. USE: '$0 print [FILE]'"
	}
	[ ! -f $1 ] && {
		[ $ONECLICK_CGI -eq 1 ] && { echo "ERROR: File $1 not found."; exit 1; } ||
		qmp_error "File $1 not found."
		
	}
	local var
	for var in $ONECLICK_VARS; do
		echo " $var='`grep "$var" $1 | awk -F "=" '{print $2}' | tr -d "'" | sed 's/\ /_/g'`'"
	done	
	
	return 0
}

configure() {
	echo "Configuring the node, please wait..."

	[ -z $1 ] && {
		[ $ONECLICK_CGI -eq 1 ] && { echo "ERROR: No file given"; exit 1; } ||
		qmp_error "No file given: USE: '$0 configure [FILE]'"
	}

	# SET COMMUNITY MODE, DHCP AND PUBLISH LAN
	uci set qmp.roaming.ignore=1
	uci set qmp.networks.publish_lan=1
	uci set qmp.networks.disable_lan_dhcp=0

	# SET LAN IP
	local ip="`grep "ip" $1 | awk -F "=" '{print $2}' | tr -d "'" | sed 's/\ /_/g'`"
	uci set qmp.networks.lan_address="$ip"

	# SET LAN MASK
	local mask="`grep "mask" $1 | awk -F "=" '{print $2}' | tr -d "'" | sed 's/\ /_/g'`"
	uci set qmp.networks.lan_netmask="$mask"

	# SET BMX IP mask (CIDR)
	local cidrmask=0
	IFS="."
	for dec in $mask; do
		while [ $dec -gt 0 ]; do
			cidrmask=$(($cidrmask+$dec%2))
			dec=$(($dec/2))
		done
	done
	IFS="\ "
	uci set qmp.networks.bmx6_ipv4_address="$ip/$cidrmask"

	# GET NODE DEVICE NAME - ZONE ID - ZONE CHANNEL
	local nodename="`grep "nodename" $1 | awk -F "=" '{print $2}' | tr -d "'" | sed 's/\ /_/g'`"
	local latitude="`grep "latitude" $1 | awk -F "=" '{print $2}' | tr -d "'" | sed 's/\ /_/g'`"
	local longitude="`grep "longitude" $1 | awk -F "=" '{print $2}' | tr -d "'" | sed 's/\ /_/g'`"
	local devname="`grep "devname" $1 | awk -F "=" '{print $2}' | tr -d "'" | sed 's/\ /_/g'`"
	local zone="`grep "zone" $1 | awk -F "=" '{print $2}' | tr -d "'" | sed 's/\ /_/g'`"

	# SET NODE NAME
	# TO DO: SET ZONE ID IN NAME (OR NOT)
	uci set qmp.node.community_id="$devname"

        # SET COORDINATES
	uci set qmp.node.latitude="$latitude"
	uci set qmp.node.longitude="$longitude"

        # Select radio mode to set SSID
	local j=0
	local mode ssid
	while qmp_uci_test qmp.@wireless[$j]; do
		mode=$(uci get qmp.@wireless[$j].mode)
		echo $mode | grep -q "adhoc" 2>/dev/null
		[ $? -eq 0 ] && ssid="guifi.net/${nodename}"
		[ "$mode" == "ap" ] && ssid="${nodename}-AP"
		uci set qmp.@wireless[$j].name=$ssid
		j=$(( $j + 1 ))
	done

	# If mini_snmpd present configure it with wlan0 (used by Guifi.net graphics)
	[ -f /etc/config/mini_snmpd ] && {
		uci set mini_snmpd.@mini_snmpd[0].enabled=1
		uci set mini_snmpd.@mini_snmpd[0].contact="guifi@guifi.net"
		uci set mini_snmpd.@mini_snmpd[0].location="$nodename"
		INTERFACES=$(uci get mini_snmpd.@mini_snmpd[0].interfaces)
		echo $INTERFACES | grep 'wlan0' 2> /dev/null
		[ $? -ne 0 ] && uci add_list mini_snmpd.@mini_snmpd[0].interfaces="wlan0"
        }

	# Set filter to update with image that includes 'qmp-guifi' package
	uci set qmp.update.filter="qMp-Guifi.*sysupgrade"

	echo;
	uci commit
	sleep 1
#	qmpcontrol configure_network ; qmpcontrol configure_wifi ; /etc/init.d/mini_snmpd restart # ; /etc/init.d/bmx6 restart
	qmpcontrol configure_all ; /etc/init.d/mini_snmpd restart # ; /etc/init.d/bmx6 restart
	return 0
}

oneclick() {
	[ ! -z $1 ] && oneclick_url=$1 || help
	[ ! -z $2 ] && oneclick_file=$2 || oneclick_file=$ONECLICK_FILE
	
	# GETTING ONECLICK CONFIG
	get_url $oneclick_url $oneclick_file
	[ $? -ne 0 ] && qmp_error "Unexpected error in qmpguifi get_url function"
	echo;
	
	# CHECKING DOWNLOADED CONFIG
	check $oneclick_file
	[ $? -ne 0 ] && qmp_error "Unexpected error in qmpguifi check function"
	echo;

	# PRINTING CONFIG VARIABLES
	print $oneclick_file
	[ $? -ne 0 ] && qmp_error "Unexpected error in qmpguifi print function"
	echo;
	
	# CONFIGURING QMP SYSTEM
	read -p "Do you want to configure your node with this settings? [N,y]" a
	echo;
	[ "$a" == "y" ] && {
		configure $oneclick_file
		[ $? -ne 0 ] && qmp_error "Unexpected in qmpguifi configure function"
		echo "Configuration done!"; echo;
		rm -f $oneclick_file
	} || {
		echo "Doing nothing."; echo;
		rm -f $oneclick_file
	}
	return 0
}

help() {
	echo "Use: $0 <function> [params]"
	echo ""
	echo "get_url [URL] [FILE]  : Get oneclick file."
	echo "check [FILE]          : Check if valid onelick file."
	echo "print [FILE]          : Print oneclick file values."
	echo "configure [FILE]      : Configure node with oneclick file values (recommended to check file before)."
	echo "-"
	echo "oneclick [URL]        : Do all configuration based on Guifi.net website data."
	echo ""
	exit 1;
}

[ -z "$1" ] && help
$@; [ $? -ne 0 ] && help || return 0

