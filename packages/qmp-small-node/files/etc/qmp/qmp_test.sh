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
index=2
$QMPINFO channels wlan1

channel_info="$($QMPINFO channels wlan1 | awk NR==$(qmp_get_dec_node_id)%10+$index+1)" 

echo $channel_info
