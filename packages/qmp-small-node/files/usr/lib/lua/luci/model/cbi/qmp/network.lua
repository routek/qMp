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
lan = eth_section:option(MultiValue, "lan_devices", "LAN devices","These devices will be used for user end connection")
for i,l in ipairs(eth_int) do
	lan:value(l,l)
end

-- Option wan_device
wan = eth_section:option(MultiValue, "wan_devices", "WAN devices","These devices will be used for internet or any other gateway connection")
for i,w in ipairs(eth_int) do
	wan:value(w,w)
end

-- Option mesh_devices
mesh = eth_section:option(MultiValue, "mesh_devices", "MESH devices","These devices will be used for Mesh network")
for i,l in ipairs(eth_int) do
        mesh:value(l,l)
end

function m.on_commit(self,map)
        luci.sys.call('/etc/qmp/qmp_control.sh configure_network > /tmp/qmp_control_network.log &')
end


return m

