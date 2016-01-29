m = Map("qmp", translate("qMp network settings"), translate("Here you can configure all the network settings of your qMp device, like the IP addresses, network roles, etc."))

net = m:section(NamedSection, "network", "qmp", translate("Network settings"))
net.anonymous = true
net.addremove = false

dev = m:section(NamedSection, "devices", "qmp", translate("Network devices"))
dev.anonymous = true
dev.addremove = false

-- IP addressing
net:tab("ip", translate("IP addresses"), translate("Fill in the fields below the IP addressing configuration."))

-- Mode
mode = net:taboption("ip", Value, "mode", translate("Network mode:"), translate("Community (public addressing) / NAT (private addresses) / Roaming (experimental)"))
mode.datatype = "string"
mode.default = "nat"
mode.maxlength = 195
mode.optional = false
mode.rmempty = false


--[[ -- Ethernet tab
net:tab("ethernet", translate("Ethernet devices"), translate("Use this page to configure the Ethernet devices and their roles. "))

-- Node latitude
loc_lat = net:taboption("ethernet", Value, "latitude", translate("Latitude (°)"), translate ("The device's latitude geoposition (north/south) on the map (e.g. \"0.1234\")."))
loc_lat.datatype = "float"
loc_lat.default = 0.0
]]--


-- Advanced network tab
dev:tab("adv", translate("Advanced network setting"), translate("Use this page to configure the Ethernet devices and their roles. "))

-- Node latitude
lan = dev:taboption("adv", Value, "lan_devices", translate("LAN devices:"), translate ("Devices in LAN mode."))
lan.datatype = "list"

return m