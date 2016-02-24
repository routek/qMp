#!/bin/sh
QMP_PATH="/etc/qmp"

[ -z "$SOURCE_COMMON" ] && . $QMP_PATH/qmp_common.sh
[ -z "$SOURCE_FUNCTIONS" ] && . $QMP_PATH/qmp_functions.sh

QMP_VERSION="$QMP_PATH/qmp.version"

qmp_update_get_local_hash() {
	device_hash="$( ( [ -f /tmp/sysinfo/board_name ] && cat /tmp/sysinfo/board_name || cat /proc/cpuinfo | egrep "^vendor_id|^model name|^machine") | md5sum | awk '{print $1}' )"
	qmp_debug "My local device hash is $device_hash"
	echo "$device_hash"
}

qmp_update_get_current_timestamp() {
	cat $QMP_VERSION
}

qmp_update_get_url() {
	qmp_debug "Fetching $1"
	wget -q $1 -O- 2>/dev/null
	[ $? -ne 0 ] && qmp_error "Cannot fetch $1"
}

qmp_update_get_my_device() {
	devices_url="$1"
	device_hash="$2"
	qmp_update_get_url $devices_url | grep "^$device_hash" | awk '{print $2}'
}

qmp_update_get_last_image_name() {
	images_url=$1
	filter=$2
	qmp_update_get_url $images_url | egrep "$filter" | grep "$my_device" | awk '{print $2}' | sort -n -r | awk NR==1
}

qmp_update_get_checksum_from_image() {
	images_url=$1
	image_name=$2
	qmp_update_get_url $images_url | grep "$image_name" | awk '{print $1}'
}

qmp_update_extract_timestamp() {
	image_name="$1"
	echo $image_name | awk -F_ '{print $NF}' | awk -F\- '{print $1}'
}

qmp_update_get_config() {
        url="$(qmp_uci_get update.url)"
        [ -z "$url" ] && url="http://fw.qmp.cat"

        images="$(qmp_uci_get update.images)"
        [ -z "$images" ] && images="IMAGES"

        devices="$(qmp_uci_get update.devices)"
        [ -z "$devices" ] && devices="DEVICES"

	filter="$(qmp_uci_get update.filter)"
	[ -z "$filter" ] && filter="sysupgrade"
}

qmp_update_check() {
	qmp_update_get_config

	device_hash="$(qmp_update_get_local_hash)"

	my_device="$(qmp_update_get_my_device $url/$devices $device_hash $filter)"
	[ -z "$my_device" ] && qmp_error "I am sorry, I cannot find an image for your device in $url"
	qmp_debug "My device is $my_device"

	last_image="$(qmp_update_get_last_image_name $url/$images $filter)"
	qmp_debug "The last image name is $last_image"

	[ -z "$last_image" ] && qmp_error "I cannot find an image for your device $my_device in $url"

	last_timestamp="$(qmp_update_extract_timestamp $last_image)"
	current_timestamp="$(qmp_update_get_current_timestamp)"

	if [ $current_timestamp -lt $last_timestamp ]; then
		checksum="$(qmp_update_get_checksum_from_image $url/$images $last_image)"
		echo "$url/$last_image $checksum"
	fi
}

qmp_update_save_config() {
	local d
	local preserve=""
	# Checking if the preserve files/directory exist
	for d in $@; do
		[ -e "$d" ] && preserve="$preserve $d"
	done

	cd /
	tar czf /tmp/qmp_saved_config.tar.gz $preserve
	[ $? -ne 0 ] && qmp_error "Cannot save config: $@"
	echo "/tmp/qmp_saved_config.tar.gz"
}


# If first parameter is an URL, get the image from this URL. If not uses the qMp upgrade system
qmp_update_upgrade_system() {
	image_url="$1"

	if [ -z "$image_url" ]; then
		last_update_info="$(qmp_update_check)"
		image_url="$(echo $last_update_info | awk '{print $1}')"
		checksum="$(echo $last_update_info | awk '{print $2}')"
		[ -z "$image_url" ] && qmp_error "No new system image found"
		[ -z "$checksum" ] && qmp_error "Checksum not found!"
		qmp_log "Found new system image at $image_url"
	fi

	# Getting image from HTTP/FTP or from filesystem
	if [ -n "$(echo $image_url | egrep 'http|ftp')" ]; then
		# Downloading image
		output_image="/tmp/qmp_upgrade_image.bin"
		rm -f /tmp/qmp_upgrade_image.bin 2>/dev/null
		qmp_log "Downloading image $image_url"
		wget -q $image_url -O $output_image 2>/dev/null
	else
		output_image=$image_url
	fi

	# Checking checksum
	if [ -n "$checksum" ]; then
		checksum_local="$(md5sum /tmp/qmp_upgrade_image.bin | awk '{print $1}')"
		[ "$checksum_local" != "$checksum" ] && qmp_error "Upgrade not possible, checksum missmatch. Try again!"
		qmp_log "Checksum correct!"
	fi

	# Saving configuration
	preserve="$(qmp_uci_get update.preserve)"
	if [ -z "$preserve" ]; then
		qmp_log "qmp.update.preserve is empy. For security I will preserve /etc/config/qmp. Specify \"none\" if you want to preserve nothing"
		preserve="/etc/config/qmp"
	fi

	if [ "$preserve" != "none" ]; then
		config="$(qmp_update_save_config $preserve)"
	fi

	read -p "Do you want to upgrade system using image $image_url? [N,y] " a
	if [ "$a" == "y" ]; then
		echo "Upgrading..."
		[ -n "$config" ] && sysupgrade -f $config $output_image
		[ -z "$config" ] && sysupgrade -n $output_image
	else
		echo "Doing nothing..."
		rm -f $output_image
		return 1
	fi

	return 0
}
