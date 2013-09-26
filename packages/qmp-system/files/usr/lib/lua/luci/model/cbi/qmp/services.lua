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

local m = Map("qmp", "Quick Mesh Project")

local section = m:section(NamedSection, "services", "qmp", translate("Services"), translate("System services control"))
section.addremove = False

-- Option: VPN
local vpn = section:option(Flag, "vpn", translate("Management VPN"),
translate("The Management VPN is used to control the nodes in remote from a central point"))
vpn.default=0

-- Option: Captive Portal
local cp = section:option(Flag, "captive_portal", translate("Captive Portal"),                                                                                                       
translate("The captive portal is a small http proxy used to show a HTML page the first time someone connects to the node's Access Point"))          
cp.default=0

-- Option: b6m
local b6m = section:option(Flag, "b6m", translate("BMX6 map"),                                                                                                       
translate("The b6m is a real time descentralized geopositioning map based on OpenStreetMaps (Internet access only required for the OSM but not for the status/topology)"))
b6m.default=0

-- Option: altermap
local alt = section:option(Flag, "altermap", translate("Altermap"),                                                                                                       
translate("AlterMap is a centralized geopositioning map. Internet and the previous creation of the node in the map page are required (http://map.qmp.cat)"))
alt.default=0

-- Option: gwck
local gwck = section:option(Flag, "gwck", translate("Gateway Checker"),                                                                                                       
translate("GWCK is a tool automatic discover and publish Internet access among the Mesh network"))
gwck.default=0

-- Option: bwtest
local bwt = section:option(Flag, "bwtest", translate("Bandwidth test"),                                                                                                       
translate("If enabled, the node will be available to perform bandwidth test from other locations"))
bwt.default=0

function m.on_commit(self,map)
	luci.sys.call('/etc/qmp/qmp_control.sh apply_services > /tmp/qmp_apply_services.log &')
	http.redirect("/luci-static/resources/qmp/wait_short.html")
end

return m

