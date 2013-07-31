#!/bin/sh
#    Copyright © 2012 Fundacio Privada per a la Xarxa Oberta, Lliure i Neutral guifi.net
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
#    with this program. If not, see <http://www.gnu.org/licenses/>.
#
# Contributors:
#	Simó Albert i Beltran
#
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
		/etc/init.d/network restart
		if /etc/init.d/gwck enabled
		then
			/etc/init.d/gwck restart
		fi
		/etc/init.d/bmx6 restart
	}
}
