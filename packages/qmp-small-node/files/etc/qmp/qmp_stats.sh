#!/bin/sh
# Importing functions
QMP_PATH="/etc/qmp"
. $QMP_PATH/qmp_common.sh

# Configuration options
OUTPUT="/root/stats"
WIFI_DEVS="$(qmp_get_wifi_devices)"
LAN="br-lan"
SEP=" "

# Preparing environment
[ ! -d "$OUTPUT" ] && mkdir $OUTPUT

# Returns the time in UNIX format
get_time() {
	date +%s
}

# Returns the number of dhcp leases
dhcp_leases() {
	cat /tmp/dhcp.leases  | wc -l
}

# Returns the number of associatet stations for dev=$1
assoc_list() {
	iw $1 station dump| grep Station | wc -l
}

# Returns the total amount of data transfered by interface LAN
lan_bw() {
	cat /proc/net/dev | grep $LAN | cut -d: -f2 | awk -v SEP="$SEP" '{print $1/1048576 SEP $9/1048576}'
}

# Returns the current load avarage (5min)
load_avg() {
	cat /proc/loadavg | awk '{print $2*100}'
}

# Returns the number of nodes seen by the mesh protocol
nodes_seen() {
	echo "$(($(qmpinfo nodes | wc -l)-1))"
}

# Returns the signal avarage of associated stations for dev=$1
signal_avg() {
	signals=$(iw $1 station dump | grep "signal avg" | awk '{print $3}')
	total=0
	stations=0
	for n in $signals; do total=$(($total+$n)); stations=$(($stations+1)); done 
	[ $stations -gt 0 ] &&	echo "$(($total/$stations))"
}

## MAIN 

echo "$(get_time)${SEP}$(dhcp_leases)" >> $OUTPUT/leases.log
echo "$(get_time)${SEP}$(lan_bw)" >> $OUTPUT/lan_bw.log
echo "$(get_time)${SEP}$(load_avg)" >> $OUTPUT/load.log
echo "$(get_time)${SEP}$(nodes_seen)" >> $OUTPUT/nodes.log

for d in $WIFI_DEVS; do
	echo "$(get_time)${SEP}$(assoc_list $d)" >> $OUTPUT/wifi_assoc_$d.log
	echo "$(get_time)${SEP}$(signal_avg $d)" >> $OUTPUT/wifi_signal_$d.log
done
