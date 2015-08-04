#!/bin/sh
# Check if bmx6 is stoped
[ ! -f /proc/$(cat /var/run/bmx6/pid)/status ] && {
	echo "[$(date)] Starting bmx6, it was down."
	logread > /tmp/bmx6_crash_$(date +%Y%m%d_%H%M).log
	/etc/init.d/bmx6 restart
} || {
	# Check if there is some interface working
	[ $(bmx6 -c show=interfaces| grep -c UP) -le 0 ] && {
		echo "[$(date)] There is no interface working, restarting network and bmx6."
		logread > /tmp/bmx6_crash_$(date +%Y%m%d_%H%M).log
		/etc/init.d/network reload
		if /etc/init.d/gwck enabled
		then
			/etc/init.d/gwck restart
		fi
		/etc/init.d/bmx6 restart
	}
}
