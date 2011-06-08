qmp_configure_wifi_device() {
	echo "Configuring device $1"
}

qmp_configure_wifi() {
	devices="$(ip link | grep  -E ": (wifi|wlan).: "| cut -d: -f2)"
	macs="$(ip link | grep -A1 -E ": (wifi|wlan).: " | grep link | cut -d' ' -f6)"
	i=1
	for d in $devices; do 
		m=$(echo $macs | cut -d' ' -f$i)
		j=0
		configured_mac="$(qmp_uci_get @wireless[$j].mac)"
		while [ ! -z "$configured_mac" ]; do
			[ "$configured_mac" == "$m" ] && { qmp_configure_wifi_device $j; break; }
			j=$(( $j + 1 ))
			configured_mac="$(qmp_uci_get @wireless[$j].mac)"
		done
		i=$(( $i + 1 ))
	done
		
                        
}

