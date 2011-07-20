require("luci.sys")

m = Map("qmp", "Quick Mesh Project")

ethernet_interfaces = { 'eth', 'ath', 'wlan' }
wireless_interfaces = { 'ath', 'wlan' }

eth_section = m:section(NamedSection, "interfaces", "qmp", "Interfaces", "Interfaces")
eth_section.addremove = False

--wl_section = m:section(NamedSection, "interfaces", "qmp", "Wireless interfaces", "Wireless devices")
--wl_section.addremove = False


-- Getting the physical (real) interfaces 
-- interfaces matching with real_interfaces and without dot
-- ethernet interfaces will be stored in eth_int and wireless in wl_int
eth_int = {}
for i,d in ipairs(luci.sys.net.devices()) do
	for i,r in ipairs(ethernet_interfaces) do
		if string.find(d,r) ~= nil then
			if string.find(d,"%.") == nil  then
				table.insert(eth_int,d)
			end
		end
	end
end

wl_int = {}
for i,d in ipairs(luci.sys.net.devices()) do
	for i,r in ipairs(wireless_interfaces) do
		if string.find(d,r) ~= nil then
			if string.find(d,"%.") == nil  then
				table.insert(wl_int,d)
			end
		end
	end
end

-- Option: lan_devices
lan = eth_section:option(MultiValue, "lan_devices", "LAN devices")
for i,l in ipairs(eth_int) do
	lan:value(l,l)
end

-- Option wan_device
wan = eth_section:option(ListValue, "wan_device", "WAN device")
for i,w in ipairs(eth_int) do
	wan:value(w,w)
end
wan:value(" "," ")

-- Option mesh_devices
mesh = eth_section:option(MultiValue, "mesh_devices", "MESH devices")
for i,l in ipairs(eth_int) do
        mesh:value(l,l)
end



-- Wireless devices
--for i,v in ipairs(wl_int) do
--	mode = wl_section:option(ListValue, ""
-- end	




--int:option(Value, "lan_devices", "LAN devices", "LAN devices")
--int:option(Value, "wan_device", "WAN device", "WAN devices")
--int:option(Value, "mesh_devices", "Mesh devices", "MESH devices")


return m

