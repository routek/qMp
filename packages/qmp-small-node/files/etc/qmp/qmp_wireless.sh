#!/bin/sh
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

##############################
# Global variables definition
##############################

QMP_PATH="/etc/qmp"
OWRT_WIRELESS_CONFIG="/etc/config/wireless"
TEMPLATE_BASE="$QMP_PATH/templates/wireless" # followed by .driver.mode (wireless.mac80211.adhoc)
WIFI_DEFAULT_CONFIG="$QMP_PATH/templates/wireless.default.config"
TMP="/tmp"
QMPINFO="/etc/qmp/qmpinfo"

#######################
# Importing files
######################
SOURCE_WIRELESS=1

. $QMP_PATH/qmp_common.sh

###########################
# Find wireless interface 
##########################
# Returns the index from wifi-iface (config/wireless) associated to the device or first free if not found

qmp_find_wireless_iface() {
	device=$1
	i=0
	while true; do
		d=$(qmp_uci_get_raw wireless.@wifi-iface[$i].device)
		r=$?
		[ "$d" == "$device" ] && break 
		[ $r -ne 0 ] && { qmp_uci_add_raw wireless wifi-iface; break; }
		i=$(( $i + 1 ))
	done
	echo $i
}

###################################
# Check channel for wifi interface
###################################
# First parameter: device
# Second parameter: channel
# Third parameter: mode (adhoc, ap)
# It returns the same channel if it is right, and the new one fixet if not

qmp_check_channel() {
		dev="$1"
		right_channel="$2"
		channel="$(echo $2 | tr -d +-)"
		ht40="$(echo $2 | tr -d [0-9])"
		mode="$3"
		[ ! -z "$channel" ] && chaninfo="$($QMPINFO channels $1 | grep "^$channel ")"

		# Checking if some thing related with channel is wrong
		wrong=0
		[ -z "$channel" ] || [ -z "$chaninfo" ] && wrong=1
		[ "$mode" == "adhoc" ] && [ -z "$(echo $chaninfo | grep adhoc)" ] && wrong=1
		[ "$ht40" == "+" ] && [ -z "$(echo $chaninfo | grep +)" ] && wrong=1 
		[ "$ht40" == "-" ] && [ -z "$(echo $chaninfo | grep -)" ] && wrong=1

		# If something wrong, asking for default parameter
		[ $wrong -ne 0 ] && right_channel="$(qmp_wifi_get_default channel $dev $mode)"

		echo "$right_channel"
}

#############################
# Configure driver from wifi
#############################
# This function reload modules from madwifi and mac80211 
# Also depending on which driver is configured in config file, modifies the files from /etc/modules.d 

qmp_configure_wifi_driver() {
	mac80211_modules="mac80211 ath ath5k ath9k_hw ath9k_common ath9k"
	madwifi_modules="ath_hal ath_ahb ath_pci"

	#Removing all modules
	echo "Removing wifi modules..."
	for m in $(qmp_reverse_order $mac80211_modules); do                   
		rmmod -f $m 2>/dev/null                                            
	done   
	for m in $(qmp_reverse_order $madwifi_modules); do                    
		rmmod -f $m 2>/dev/null
	done   	
		
	rmmod -a
	
	#Loading driver modules
	echo "Loading wifi modules..."
	driver="$(qmp_uci_get wireless.driver)"
	case $driver in
	"madwifi")
		mv /etc/modules.d/50-madwifi /etc/modules.d/22-madwifi 2>/dev/null
		for m in $madwifi_modules; do
			insmod $m
		done
		;;
	"mac80211")
		mv /etc/modules.d/22-madwifi /etc/modules.d/50-madwifi 2>/dev/null
		for m in $mac80211_modules; do
			insmod $m
		done
		;;
	*)
		qmp_error "Driver $driver not found"
		;;
	esac
}

########################
# Configure wifi device
########################
# Configure a wifi device according qmp config file
# Parameters are: 1-> qmp config id, 2-> device name

qmp_configure_wifi_device() {
	echo ""
	echo "Configuring device $2"

	id=$1
	device=$2

	# checking if device is configured as "none"	
	mode="$(qmp_uci_get @wireless[$id].mode)"
	[ "$mode" == "none" ] && { echo "Interface $device disabled by qmp system"; return; }  

	# spliting channel in channel number and ht40 mode	
	channel_raw="$(qmp_uci_get @wireless[$id].channel)"
	channel="$(echo $channel_raw | tr -d +-)"

	# is ht40 (802.11n) enabled?
	ht40="$(echo $channel_raw | tr -d [0-9])"
	[ ! -z "$ht40" ] && { mode="${mode}-n"; htmode="HT40$ht40"; }
	
	mac="$(qmp_uci_get @wireless[$id].mac)"
	name="$(qmp_uci_get @wireless[$id].name)"
	driver="$(qmp_uci_get wireless.driver)"
	country="$(qmp_uci_get wireless.country)"
	bssid="$(qmp_uci_get wireless.bssid)"
	
	echo "------------------------"
	echo "Mac: $mac"
	echo "Mode: $mode"
	echo "Driver: $driver"
	echo "Channel: $channel"
	echo "Country: $country"	
	echo "Name: $name"
	echo "------------------------"

	template="$TEMPLATE_BASE.$driver.$mode"

	[ ! -f "$template" ] && qmp_error "Template $template not found"

	index=$(qmp_find_wireless_iface $device)

	# Non list arguments
	cat $template | grep -v "^list " | sed -e s/"#QMP_DEVICE"/"$device"/ \
	 -e s/"#QMP_TYPE"/"$driver"/ \
	 -e s/"#QMP_MAC"/"$mac"/ \
	 -e s/"#QMP_CHANNEL"/"$channel"/ \
	 -e s/"#QMP_COUNTRY"/"$country"/ \
	 -e s/"#QMP_SSID"/"$name"/ \
	 -e s/"#QMP_HTMODE"/"$htmode"/ \
	 -e s/"#QMP_BSSID"/"$bssid"/ \
	 -e s/"#QMP_INDEX"/"$index"/ \
	 -e s/"#QMP_MODE"/"$mode"/ > $TMP/qmp_wireless_temp

	qmp_uci_import $TMP/qmp_wireless_temp

	# List arguments
	cat $template | grep "^list " | sed s/"^list "//g | sed -e s/"#QMP_DEVICE"/"$device"/ | \
	while read l; do
		qmp_uci_add_list_raw $l
	done

	uci reorder wireless.@wifi-iface[$index]=16
	uci commit
	rm -f $TMP/qmp_wireless_temp
}

#############################
# Configure all wifi devices
#############################
#This function search for all wifi devices and leave them configured according qmp config file

qmp_configure_wifi() {

	echo "Configuring driver..."
	qmp_configure_wifi_driver

	echo "Backuping wireless config file to: $OWRT_WIRELESS_CONFIG.qmp_backup"
	cp $OWRT_WIRELESS_CONFIG $OWRT_WIRELESS_CONFIG.qmp_backup 2>/dev/null
	echo "" > $OWRT_WIRELESS_CONFIG

	devices="$(qmp_get_wifi_devices)"
	macs="$(qmp_get_wifi_mac_devices)"
	i=1
	for d in $devices; do 
		m=$(echo $macs | cut -d' ' -f$i)
		j=0
		while [ ! -z "$(qmp_uci_get @wireless[$j])" ]; do
			configured_mac="$(qmp_uci_get @wireless[$j].mac | tr [A-Z] [a-z])"
			[ "$configured_mac" == "$m" ] && { qmp_configure_wifi_device $j $d ; break; }
			j=$(( $j + 1 ))
		done
		i=$(( $i + 1 ))
	done
	
	echo ""
	echo "Done. All devices configured according qmp configuration"
}

####################
# Get default values
####################
# This function returns the default values
#  - first parameter: is always what are you asking for (mode, channel, name,...)
#  - second parameter: is device name, only needed by mode and channel
#  - third parameter: is configured mode, only needed by chanel

qmp_wifi_get_default() {
	what="$1"
	device="$2"

	# MODE
	# default mode for the second card (index=1) is AP
	# the rest are ad-hoc
	if [ "$what" == "mode" ]; then
		index=$(echo $device | tr -d [A-z])
		if [ $index -eq 1 ]; then 
			echo "ap"
		else
			echo "adhoc"
		fi
	
	# CHANNEL
	# Default channel depends on the card and on configured mode
	#  Highest channel -> adhoc or not-configured
	#  Lower channel -> ap

	elif [ "$what" == "channel" ]; then
		[ -z "$device" ] && qmp_error "Device not found?" 
		mode="$3"

		# we are using index var to put devices in different channels
		index=$(echo $device | tr -d [A-z])
		index=$(( $index * 2 ))

		# QMPINFO returns a list of avaiable channels in this format: 130 ht40+ adhoc
		[ "$mode" == "adhoc" ] || [ -z "$mode" ] && channel_info="$(qmp_tac $QMPINFO channels $device | grep adhoc | awk NR==$index+1)"
		[ "$mode" == "ap" ] && channel_info="$($QMPINFO channels $device | awk NR==$(qmp_get_dec_node_id)%10+$index+1)" 
		
		# if there is some problem, channel 6 is used
		if [ -z "$channel_info" ]; then
			qmp_log "Warning, not usable channels found in device $device "
			[ "$1" == "channel" ] && echo "6"	
			return
		fi
		
		# let's see if we can use ht40 mode
		# if it is avaiable, channel must be configured with + or - symbol 
		channel="$(echo $channel_info | cut -d' ' -f1)"
		ht40="$(echo $channel_info | cut -d' ' -f2)"
		[ "$ht40" == "ht40+" ] && channel="${channel}+"
		[ "$ht40" == "ht40-" ] && channel="${channel}-"
			
		echo "$channel"			

	# REST OF DEFAULT VAULES
	# The rest of default values are taken from the template
	else
		[ ! -f "$WIFI_DEFAULT_CONFIG" ] && qmp_error "Template not found $WIFI_DEFAULT_CONFIG"
		cat $WIFI_DEFAULT_CONFIG | grep $what | cut -d' ' -f2
	fi
}

qmp_configure_wifi_initial() {

	macs="$(qmp_get_wifi_mac_devices)"

	#Looking for configured devices
	id_configured=""
	to_configure=""
	for m in $macs; do
		found=0
		j=0
		while [ ! -z "$(qmp_uci_get @wireless[$j])" ]; do
			configured_mac="$(qmp_uci_get @wireless[$j].mac | tr [A-Z] [a-z])"
			if [ "$configured_mac" == "$m" ]; then   
				#If we found configured device, we are going to check all needed parameters
				found=1 
				device="$(qmp_get_dev_from_mac $m)"
				id_configured="$id_configured $j" 
				echo "Found configured device: $m"
		        [ -z "$(qmp_uci_get @wireless[$j].mode)" ] && qmp_uci_set @wireless[$j].mode $(qmp_wifi_get_default mode $device)
        		[ -z "$(qmp_uci_get @wireless[$j].name)" ] && qmp_uci_set @wireless[$j].name $(qmp_wifi_get_default name)
	
				# If channel is configured, we are going to check it
				# if not, using default one
				sleep 1 && mode="$(qmp_uci_get @wireless[$j].mode)"
				channel="$(qmp_uci_get @wireless[$j].channel)"
				if [ -z "$channel" ]; then 
					 qmp_uci_set @wireless[$j].channel $(qmp_wifi_get_default channel $device $mode)

				else
					newchan="$(qmp_check_channel $device $channel $mode)"
					if [ "$newchan" != "$channel" ]; then
						qmp_log Warning: "Channel $channel for device $device in mode $mode is not right, using default one"
						qmp_uci_set @wireless[$j].channel $newchan	
					fi  
				fi			
								 
				qmp_uci_set @wireless[$j].device $device
				break
			fi
			j=$(( $j + 1 ))
		done
		
		[ $found -eq 0 ] && to_configure="$to_configure $m"
	done

	#Configuring devices not found before
	for m in $to_configure; do
		device=$(qmp_get_dev_from_mac $m)
		echo "Configuring device: $device | $m"
		#Looking for a free slot to put new configuration
		j=0
		while [ ! -z "$(echo $id_configured | grep $j)" ]; do j=$(( $j +1 )); done
		#Now we have a free slot, let's go to configure device
		[ -z "$(qmp_uci_get @wireless[$j])" ] && qmp_uci_add wireless
		[ -z "$(qmp_uci_get @wireless[$j].mode)" ] && qmp_uci_set @wireless[$j].mode $(qmp_wifi_get_default mode $device)
		[ -z "$(qmp_uci_get @wireless[$j].name)" ] && qmp_uci_set @wireless[$j].name $(qmp_wifi_get_default name)
		sleep 1 && mode="$(qmp_uci_get @wireless[$j].mode)"
		[ -z "$(qmp_uci_get @wireless[$j].channel)" ] && qmp_uci_set @wireless[$j].channel $(qmp_wifi_get_default channel $device $mode)
		qmp_uci_set @wireless[$j].mac $m
		qmp_uci_set @wireless[$j].device $device
		id_configured="$id_configured $j"
	done

	#Finally we are going to configure default parameters if they are not present
	[ -z "$(qmp_uci_get wireless)" ] && qmp_uci_set wireless qmp
	[ -z "$(qmp_uci_get wireless.driver)" ] && qmp_uci_set wireless.driver $(qmp_wifi_get_default driver)
	[ -z "$(qmp_uci_get wireless.country)" ] && qmp_uci_set wireless.country $(qmp_wifi_get_default country)
	[ -z "$(qmp_uci_get wireless.bssid)" ] && qmp_uci_set wireless.bssid $(qmp_wifi_get_default bssid)
}                        
