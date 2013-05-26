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
m = Map("qmp", "Quick Mesh Project")

eth_section = m:section(NamedSection, "interfaces", "qmp", "Interfaces", "Interfaces")
eth_section.addremove = False

-- Getting the physical (real) interfaces
net_int = qmpinfo.get_devices().all

-- Option: lan_devices
lan = eth_section:option(MultiValue, "lan_devices", "LAN devices","These devices will be used for end-user connection (DHCP server)")
for i,l in ipairs(net_int) do
	lan:value(l,l)
end

-- Option wan_device
wan = eth_section:option(MultiValue, "wan_devices", "WAN devices","These devices will be used for internet or any other gateway connection (DHCP client)")
for i,w in ipairs(net_int) do
	wan:value(w,w)
end

-- Option mesh_devices
mesh = eth_section:option(MultiValue, "mesh_devices", "MESH devices","These devices will be used for Mesh network")
for i,l in ipairs(net_int) do
        mesh:value(l,l)
end

no_vlan = eth_section:option(Value, "no_vlan_devices", translate("No VLAN devices"),translate("Devices we want to use without VLAN tagging (not recommended)"))

function m.on_commit(self,map)
	http.redirect("/luci-static/resources/qmp/wait_long.html")
        luci.sys.call('qmpcontrol configure_network > /tmp/qmp_control_network.log &')
end


return m

