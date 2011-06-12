#!/bin/sh
QMP_PATH="/etc/qmp"
OWRT_WIRELESS_CONFIG="/etc/config/wireless"
TEMPLATE_BASE="$QMP_PATH/templates/wireless"

. $QMP_PATH/qmp_common.sh

qmp_configure_wifi_device() {
	echo "Configuring device $1"
	mac="$(qmp_uci_get @wireless[$1].mac)"
	channel="$(qmp_uci_get @wireless[$1].channel)"
	mode="$(qmp_uci_get @wireless[$1].mode)"
	name="$(qmp_uci_get @wireless[$1].name)"
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

	cat $template | sed -e s/"#QMP_DEVICE"/"wifi$1"/ \
	 -e s/"#QMP_TYPE"/"$driver"/ \
	 -e s/"#QMP_MAC"/"$mac"/ \
	 -e s/"#QMP_CHANNEL"/"$channel"/ \
	 -e s/"#QMP_COUNTRY"/"$country"/ \
	 -e s/"#QMP_SSID"/"$name"/ \
	 -e s/"#QMP_BSSID"/"$bssid"/ \
	 -e s/"#QMP_MODE"/"$mode"/ >> $OWRT_WIRELESS_CONFIG 
}

qmp_configure_wifi() {
	echo "Backuping wireless config file to: $OWRT_WIRELESS_CONFIG.qmp_backup"
	cp $OWRT_WIRELESS_CONFIG $OWRT_WIRELESS_CONFIG.qmp_backup
	echo "" > $OWRT_WIRELESS_CONFIG

	devices="$(ip link | grep  -E ": (wifi|wlan).: "| cut -d: -f2)"
	macs="$(ip link | grep -A1 -E ": (wifi|wlan).: " | grep link | cut -d' ' -f6)"
	i=1
	for d in $devices; do 
		m=$(echo $macs | cut -d' ' -f$i)
		j=0
		configured_mac="$(qmp_uci_get @wireless[$j].mac | tr [A-Z] [a-z])"
		while [ ! -z "$configured_mac" ]; do
			[ "$configured_mac" == "$m" ] && { qmp_configure_wifi_device $j ; break; }
			j=$(( $j + 1 ))
			configured_mac="$(qmp_uci_get @wireless[$j].mac | tr [A-Z] [a-z])"
		done
		i=$(( $i + 1 ))
	done
	echo "Done. All devices configured according qmp configuration"
}
                        
