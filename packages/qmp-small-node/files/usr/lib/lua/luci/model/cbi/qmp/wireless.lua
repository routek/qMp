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
package.path = package.path .. ";/etc/qmp/?.lua"
qmp = require "qmpinfo"

device_names = {"wlan","ath","wifi"}

m = Map("qmp", "Quick Mesh Project")

local uci = luci.model.uci.cursor()
local wdevs = {}
for k,v in pairs(uci:get_all("qmp")) do
	for _,n in ipairs(device_names) do
		if v.device ~= nil and string.find(v.device,n) then
			table.insert(wdevs,k)
		end
	end
end

---------------------------
-- Section Wireless Main --
---------------------------
s_wireless_main = m:section(NamedSection, "wireless", "qmp", "Wireless general options", "")
s_wireless_main.addremove = False

-- Driver selection
driver = s_wireless_main:option(ListValue, "driver", "Driver")
driver:value("mac80211","mac80211")
driver:value("madwifi","madwifi")

-- Country selection
country = s_wireless_main:option(Value,"country", "Country")

-- BSSID
bssid = s_wireless_main:option(Value,"bssid","BSSID")

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
	mode:value("adhoc","Ad-Hoc")
	mode:value("ap","Access Point")
	mode:value("none","Not used")
	
	-- Name
	s_wireless:option(Value,"name","Wireless name")
	
	-- Channel
	channel = s_wireless:option(ListValue,"channel","Channel")
	mymode = m.uci:get("qmp",wdev,"mode")

	for _,ch in ipairs(qmp.get_channels(mydev)) do
		if mymode ~= "adhoc" or ch.adhoc then  
			channel:value(ch.channel, ch.channel)
			if ch.ht40p then channel:value(ch.channel .. '+', ch.channel .. '+') end
			if ch.ht40m then channel:value(ch.channel .. '-', ch.channel .. '-') end
		end
	end

	-- Txpower
	txpower = s_wireless:option(ListValue,"txpower","Power")	
	for _,t in ipairs(qmp.get_txpower(mydev)) do
		txpower:value(t,t)
	end
end

function m.on_commit(self,map)
	luci.sys.call('/etc/qmp/qmp_control.sh apply_wifi > /tmp/qmp_control_wifi.log &')
end


return m

