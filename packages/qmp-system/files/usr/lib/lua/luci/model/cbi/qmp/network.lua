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
package.path = package.path .. ";/etc/qmp/?.lua"
qmpinfo = require "qmpinfo"                     
require("luci.sys")

local http = require "luci.http"
m = Map("qmp", "qMp network settings")

eth_section = m:section(NamedSection, "interfaces", "qmp", translate("Network mode"), translate("Select the working mode of the wired network interfaces: <br/> · LAN mode is used to provide end-users connectivity and a DHCP will be enabled to assign IP addresses to the devices connecting.<br/> · WAN mode is used on interfaces connected to an Internet up-link or any other gateway connection.<br/> <br/>LAN and WAN modes are mutually exclusive. <strong>Do not set an interface in both LAN and WAN modes.</strong>"))
eth_section.addremove = False

mesh_section = m:section(NamedSection, "interfaces", "qmp", translate("Mesh interfaces"), translate("Select the devices that will be used in the mesh network. It is recommended to select them all."))
eth_section.addremove = False

special_section = m:section(NamedSection, "interfaces", "qmp", translate("Special settings"), translate("Use this section to disable VLAN tagging in certain interfaces or to exclude them from qMp."))
mesh_section.addremove = False

-- Getting the physical (real) interfaces
net_int = qmpinfo.get_devices().all

-- Option: lan_devices
lan = eth_section:option(MultiValue, "lan_devices", translate("LAN mode"),translate("Interfaces used to provide end-user connectivity (DHCP server)"))
local i,l
for i,l in ipairs(net_int) do
	lan:value(l,l)
end

-- Option wan_device
wan = eth_section:option(MultiValue, "wan_devices", "WAN mode","Interfaces connected to an Internet up-link or any other gateway (DHCP client)")
for i,l in ipairs(net_int) do
	wan:value(l,l)
end

-- Option mesh_devices
mesh = mesh_section:option(MultiValue, "mesh_devices", "MESH devices","Devices used for meshing (it is recommended to check them all)")
for i,l in ipairs(net_int) do
        mesh:value(l,l)
end

no_vlan = special_section:option(Value, "no_vlan_devices", translate("VLAN-untagged devices"),translate("Devices that will not be used with VLAN tagging (it is recommended to leave it blank)"))

ignore_devs = special_section:option(Value, "ignore_devices", translate("Excluded devices"),translate("Devices that will not be used by qMp"))

function m.on_commit(self,map)
	http.redirect("/luci-static/resources/qmp/wait_long.html")
	luci.sys.call('qmpcontrol configure_network > /tmp/qmp_control_network.log &')
end


return m

