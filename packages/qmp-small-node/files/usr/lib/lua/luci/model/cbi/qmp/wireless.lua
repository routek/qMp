require("luci.sys")
package.path = package.path .. ";/etc/qmp/?.lua"
qmp = require "qmpinfo"

device_names = {"wlan","ath"}

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

end

return m

