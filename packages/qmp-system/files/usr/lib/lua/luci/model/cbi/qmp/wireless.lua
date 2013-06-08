--[[
    Copyright (C) 2011 Fundacio Privada per a la Xarxa Oberta, Lliure i Neutral guifi.net

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

    The full GNU General Public License is included in this distribution in
    the file called "COPYING".
--]]

require("luci.sys")
local http = require "luci.http"
package.path = package.path .. ";/etc/qmp/?.lua"
qmpinfo = require "qmpinfo"


m = Map("qmp", "Quick Mesh Project")

local uci = luci.model.uci.cursor()
local wdevs = qmpinfo.get_wifi_index()

---------------------------
-- Section Wireless Main --
---------------------------
s_wireless_main = m:section(NamedSection, "wireless", "qmp", translate("Wireless general options"), "")
s_wireless_main.addremove = False

-- Driver selection (deprecated)
--driver = s_wireless_main:option(ListValue, "driver", translate("Driver"))
--driver:value("mac80211","mac80211")
--driver:value("madwifi","madwifi")

-- Country selection
country = s_wireless_main:option(Value,"country", translate("Country"))

-- BSSID
bssid = s_wireless_main:option(Value,"bssid","BSSID")

-- Button Rescan Wifi devices
confwifi = s_wireless_main:option(Button, "_confwifi", translate("Reconfigure"),
translate("Rescan and reconfigure all devices. <br/>Use it just in case you have added or changed a device."))

function confwifi.write(self, section)
	luci.sys.call("qmpcontrol reset_wifi")
end


-----------------------------
-- Section Wireless Device --
-----------------------------
for _,wdev in ipairs(wdevs) do

	mydev = uci:get("qmp",wdev,"device")

	s_wireless = m:section(NamedSection, wdev, "Wireless device", "Wi-Fi " .. mydev)
	s_wireless.addremove = False

	-- Device
	dev = s_wireless:option(DummyValue,"device","Device")

	-- MAC
	mac = s_wireless:option(DummyValue,"mac","MAC")

	-- Mode
	mode = s_wireless:option(ListValue,"mode","Mode")
	mode:value("adhoc_ap","AdHoc + AP")
	mode:value("adhoc","AdHoc")
	mode:value("ap","Access Point")
	mode:value("client","Client")
	mode:value("none","Not used")

	-- Name
	s_wireless:option(Value,"name","ESSID", translate("Name of the WiFi network"))

	-- Channel
	channel = s_wireless:option(ListValue,"channel","Channel",translate("WiFi channel to be used in this device.<br/>Select +/- for 40MHz channel. Select b for 802.11b only"))
	mymode = m.uci:get("qmp",wdev,"mode")

	for _,ch in ipairs(qmpinfo.get_channels(mydev)) do
		if mymode ~= "adhoc" or ch.adhoc then
			channel:value(ch.channel, ch.channel)
			if ch.ht40p then channel:value(ch.channel .. '+', ch.channel .. '+') end
			if ch.ht40m then channel:value(ch.channel .. '-', ch.channel .. '-') end
			if ch.channel < 15 then channel:value(ch.channel .. 'b', ch.channel .. 'b') end
		end
	end

	-- WPA key
	local key=s_wireless:option(Value,"key","WPA2 key", 
		translate("WPA2 key for AP (8 chars or more).<br/>Leave blank for make it OPEN (recomended)"))
	key.default = ""
	key:depends("mode","ap")
	key:depends("mode","adhoc_ap")

	-- Txpower
	txpower = s_wireless:option(ListValue,"txpower","Power",translate("Choose the transmit power (each 4, the power is doubled)"))
	for _,t in ipairs(qmpinfo.get_txpower(mydev)) do
		txpower:value(t,t)
	end
end


function m.on_commit(self,map)
	http.redirect("/luci-static/resources/qmp/wait_short.html")
	luci.sys.call('(/etc/qmp/qmp_control.sh configure_wifi ; /etc/init.d/network reload)&')
end


return m

