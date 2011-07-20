require("luci.sys")

m = Map("qmp", "Quick Mesh Project")

------------------
-- Section MAIN
------------------
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

--------------------
-- Section Wireless
--------------------
s_wireless = m:section(TypedSection, "wireless", "Wireless devices", "")
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
--local iw = luci.sys.exec("sh /etc/qmp/qmp_common.sh qmp_get_dev_from_mac " .. "00:80:48:6b:28:83")
--luci.sys.wifi.channels(iw)

--local device = m:get(s_wireless, "channel")
--device = m:get(s_wireless,"channel")

channel = s_wireless:option(Value,"channel","Channel")


return m

