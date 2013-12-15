#!/bin/sh
#    Copyright (C) 2013 Quick Mesh Project
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

ONECLICK_CGI=0
ONECLICK_FILE="/tmp/guifi_oneclick"
ONECLICK_PATTERN="qMp Guifi-oneclick"
ONECLICK_URL="/view/unsolclic"
ONECLICK_URL_BASE="http://guifi.net/guifi/device/"
ONECLICK_VARS="nodename devname devmodel ip mask zone"
ONECLICK_ZONES="GS='124+' RAV='136' VLLC='108+'"


qmp_guifi_get_url() {
	echo "Getting oneclick config:"
	if [ -z $1 ]; then
		if [ $ONECLICK_CGI -eq 1 ]; then echo "ERROR: No URL specified."; exit 1;
		else qmp_error "No URL specified. USE: 'qmp_guifi_get <${ONECLICK_URL_BASE}#####/> <FILE>'"
		fi
	else
		echo $1 | grep -q "^http://" 2>/dev/null
		[ $? -ne 0 ] && {
			if [ $ONECLICK_CGI -eq 1 ]; then echo "ERROR: Wrong URL specified."; exit 1;
			else qmp_error "Wrong URL specified. USE 'qmp_guifi_get <${ONECLICK_URL_BASE}#####/> <FILE>'"
			fi
		}
	fi
	[ -z $2 ] && {
		if [ $ONECLICK_CGI -eq 1 ]; then echo "ERROR: No temporary file specified."; exit 1;
		else qmp_error "No temporary file specified. USE: 'qmp_guifi_get <${ONECLICK_URL_BASE}#####/> <FILE>'"
		fi
	}

	# CHECK IF UNSOLCLIC OR DEVICE URL GIVEN
	local oneclick_url
	echo $1 | grep -q "/view/unsolclic$" 2>/dev/null
	[ $? -ne 0 ] && oneclick_url=$1$ONECLICK_URL || oneclick_url=$1

	wget -q $oneclick_url -O $2 2>/dev/null	
	[ $? -ne 0 ] && rm -f $file && {
		if [ $ONECLICK_CGI -eq 1 ]; then echo "ERROR: Error downloading $oneclick_url"; exit 1;
		else qmp_error "Error downloading $oneclick_url"
		fi
	}
	
	# REMOVING "<br />" (to change output format edit guifi·net drupal module unsolclic file guifi/firmware/qmp.inc.php)
	sed -i 's/^<br \/>//g' $2

	echo "Done!"
	return 0
}

qmp_guifi_check() {
	echo "Checking oneclick config:"
	[ -z $1 ] && {
		if [ $ONECLICK_CGI -eq 1 ]; then echo "ERROR: No file given."; exit 1;
		else qmp_error "No file given. USE: 'qmp_guifi_check <FILE>'";
		fi
	}
	[ ! -f $1 ] && {
		if [ $ONECLICK_CGI -eq 1 ]; then echo "ERROR: File $1 not found."; exit 1;
		else qmp_error "File $1 not found.";
		fi
	}

	# CHECK IF VALID UNSOLCLIC CONFIG
	grep -q "$ONECLICK_PATTERN" $1 2>/dev/null
	[ $? -ne 0 ] && {
		if [ $ONECLICK_CGI -eq 1 ]; then echo "ERROR: Not valid unsolclic file. Check file or URL."; exit 1;
		else qmp_error "Not valid unsolclic file. Check file or URL.";
		fi
	} 
	
	# CHECK IF HAS MESH RADIO
	local meshradio=`grep "meshradio" $1 | awk '{FS="="; print $2}' | tr -d "'"`
	[ "$meshradio" == "no" ] && {
		if [ $ONECLICK_CGI -eq 1 ]; then echo "ERROR: No Mesh radio found. Revise your device configuration in the guifi.net website."; exit 1;
		else qmp_error "No Mesh radio found. Revise your device configuration in the guifi.net website."	
		fi
	}
	
	echo "Done!"
	return 0
}

qmp_guifi_print() {
	echo "Showing variables:"
	[ -z $1 ] && {
		if [ $ONECLICK_CGI -eq 1 ]; then echo "ERROR: No file given"; exit 1;
		else qmp_error "No file given. USE: 'qmp_guifi_print <FILE>'"
		fi
	}
	[ ! -f $1 ] && {
		if [ $ONECLICK_CGI -eq 1 ]; then echo "ERROR: File $1 not found."; exit 1;
		else qmp_error "File $1 not found."
		fi
	}
	
	local var
	for var in $ONECLICK_VARS; do
		echo " $var='`grep "$var" $1 | awk '{FS="="; print $2}' | tr -d "'" | sed 's/\ /_/g'`'"
	done	
	
	return 0
}

qmp_guifi_configure() {
	echo "Configuring the node, please wait..."
	[ -z $1 ] && {
		if [ $ONECLICK_CGI -eq 1 ]; then echo "ERROR: No file given"; exit 1;
		else qmp_error "No file given: USE: 'qmp_guifi_configure <FILE>'"
		fi
	}

	# SET COMMUNITY MODE, DHCP AND PUBLISH LAN
	uci set qmp.roaming.ignore=1
	uci set qmp.networks.publish_lan=1
	uci set qmp.networks.disable_lan_dhcp=0

	# SET LAN IP
	local ip="`grep "ip" $1 | awk '{FS="="; print $2}' | tr -d "'" | sed 's/\ /_/g'`"
	uci set qmp.networks.lan_address="$ip"

	# SET LAN MASK
	local mask="`grep "mask" $1 | awk '{FS="="; print $2}' | tr -d "'" | sed 's/\ /_/g'`"
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
	local zone="`grep "zone" $1 | awk '{FS="="; print $2}' | tr -d "'" | sed 's/\ /_/g'`"
	local nodename="`grep "nodename" $1 | awk '{FS="="; print $2}' | tr -d "'" | sed 's/\ /_/g'`"
	local devname="`grep "devname" $1 | awk '{FS="="; print $2}' | tr -d "'" | sed 's/\ /_/g'`"

	# GET CHANNEL (140- by default)
        local var zone_channel
        for var in $ONECLICK_ZONES; do
                zone_channel="`echo $var | grep $zone | awk '{FS="="; print $2}' | tr -d "'"`"
                [ ! -z $zone_channel ] && break;
        done
        [ -z $zone_channel ] && zone_channel="140-"

	# SET NODE NAME
	# TO DO: SET ZONE ID IN NAME
	uci set qmp.node.community_id="$devname-"

        ## TO DO : select AD-HOC RADIO(S) to set SSID and CHANNEL
	#...

	# SET SSID
#	echo " set SSID: guifi.net/$nodename"

	# SET CHANNEL
#	echo " set channel: $zone_channel"

	echo;
	uci commit
	sleep 1
	qmpcontrol configure_network ; qmpcontrol configure_wifi ; /etc/init.d/bmx6 restart
	return 0
}

qmp_guifi_apply() {
	[ ! -z $1 ] && oneclick_url=$1 || exit 1
	[ ! -z $2 ] && oneclick_file=$2 || oneclick_file=$ONECLICK_FILE
	
	# GETTING ONECLICK CONFIG
	qmp_guifi_get_url $oneclick_url $oneclick_file
	[ $? -ne 0 ] && qmp_error "Unexpected error in qmp_guifi_get function"
	echo;
	
	# CHECKING DOWNLOADED CONFIG
	qmp_guifi_check $oneclick_file
	[ $? -ne 0 ] && qmp_error "Unexpected error in qmp_guifi_check function"
	echo;

	# PRINTING CONFIG VARIABLES
	qmp_guifi_print $oneclick_file
	[ $? -ne 0 ] && qmp_error "Unexpected error in qmp_guifi_print function"
	echo;
	
	# CONFIGURING QMP SYSTEM
	read -p "Do you want to configure your node with this settings? [N,y]" a
	echo;
	if [ "$a" == "y" ]; then
		qmp_guifi_configure $oneclick_file
		[ $? -ne 0 ] && qmp_error "Unexpected in qmp_guifi_configure function"
		echo "Configuration done!"; echo;
		rm -f $oneclick_file
		return 0
	else
		echo "Doing nothing."; echo;
		rm -f $oneclick_file
		return 1
	fi
}

