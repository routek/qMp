#!/bin/sh
# Check if bmx7 is stoped
[ ! -f /proc/$(cat /var/run/bmx7/pid)/status ] && {
	echo "[$(date)] Starting bmx7, it was down."
	logread > /tmp/bmx7_crash_$(date +%Y%m%d_%H%M).log
	/etc/init.d/bmx7 restart
} || {
	# Check if there is some interface working
	[ $(bmx7 -c show=interfaces| grep -c UP) -le 0 ] && {
		echo "[$(date)] There is no interface working, restarting network and bmx7."
		logread > /tmp/bmx7_crash_$(date +%Y%m%d_%H%M).log
		/etc/init.d/network reload
		if /etc/init.d/gwck enabled
		then
			/etc/init.d/gwck restart
		fi
		/etc/init.d/bmx7 restart
	}
}
