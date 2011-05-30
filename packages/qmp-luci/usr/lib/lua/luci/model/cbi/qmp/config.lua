require("luci.sys")

m = Map("qmp", "Quick Mesh Project")

real_interfaces = {'eth','ath','wlan','wl'}

int = m:section(NamedSection, "interfaces", "qmp", "Interfaces", "Devices to include into Quick Mesh deployment")
int.addremove = False

-- Getting the physical (real) interfaces
-- interfaces matching with real_interfaces and without dot
phy_int = {}
for i,d in ipairs(luci.sys.net.devices()) do
	for i,r in ipairs(real_interfaces) do
		if string.find(d,r) ~= nil then
			if string.find(d,"%.") == nil  then
				table.insert(phy_int,d)
			end
		end
	end
end

-- Option: lan_devices
lan = int:option(MultiValue, "lan_devices", "LAN devices")
for i,l in ipairs(phy_int) do
	lan:value(l,l)
end

-- Option wan_device
wan = int:option(ListValue, "wan_device", "WAN device")
for i,w in ipairs(phy_int) do
	wan:value(w,w)
end
wan:value(" "," ")

-- Option mesh_devices
mesh = int:option(MultiValue, "mesh_devices", "MESH devices")
for i,l in ipairs(phy_int) do
        mesh:value(l,l)
end

--int:option(Value, "lan_devices", "LAN devices", "LAN devices")
--int:option(Value, "wan_device", "WAN device", "WAN devices")
--int:option(Value, "mesh_devices", "Mesh devices", "MESH devices")


return m

