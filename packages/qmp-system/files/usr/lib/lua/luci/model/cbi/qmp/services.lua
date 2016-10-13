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
local nixio = require "nixio"

local m = Map("qmp", "qMp node services")

local basic_services = m:section(NamedSection, "services", "qmp", translate("Basic qMp services"),
translate("These are the basic qMp services running on this node.").." "..translate("It is recommended to enable them, since they play an important role for end-user connectiviy and mesh network administration."))
basic_services.addremove = False

local additional_services = m:section(NamedSection, "services", "qmp", translate("Additional qMp services"),
translate("These are the additional services provided by this qMp node.").." "..translate("You can safely enable or disable them according to your needs without affecting basic node features or end-user connectivity."))
additional_services.addremove = False

-- Option: VPN
local vpn = additional_services:option(Flag, "vpn", translate("Management VPN"),
translate("The Management VPN is used to control the nodes remotely from a central point"))
vpn.default=0

-- Option: Captive Portal
if nixio.fs.stat("/usr/sbin/tinyproxy","type") ~= nil then
	local cp = additional_services:option(Flag, "captive_portal", translate("Captive Portal"),
	translate("The captive portal is a small http proxy used to show an HTML page the first time someone connects to the node's Access Point"))
	cp.default=0
end

-- Option: b6m
-- local b6m = additional_services:option(Flag, "b6m", translate("BMX6 map"),
-- translate("B6m is a decentralized, real-time geopositioning map based on OpenStreetMaps (Internet connection is only required for the OSM but not for the status/topology)"))
-- b6m.default=0

-- Option: libremap
local alt = additional_services:option(Flag, "libremap", translate("LibreMap"),
translate("LibreMap is a centralized geopositioning map (Internet connection is required, as well as registering the node in the map page (http://libremap.net)"))
alt.default=0

-- Option: gwck
local gwck = basic_services:option(Flag, "gwck", translate("Gateway Checker").." "..translate("(GWCK)"),
translate("GWCK is a tool to automatically discover and publish Internet gateways among the Mesh network"))
gwck.default=1

-- Option: bwtest
local bwt = basic_services:option(Flag, "bwtest", translate("Bandwidth test"),
translate("If enabled, the node will be available to perform bandwidth test from other locations"))
bwt.default=1

-- Option: mdns
if nixio.fs.stat("/usr/lib/lua/luci/model/cbi/qmp/mdns.lua","type") ~= nil then
	local mdns = basic_services:option(Flag, "mesh_dns", translate("Mesh distributed DNS"),
	translate("A distributed DNS system to publish and get domain names (example: myNode01.qmp)"))
	mdns.default=1
end

-- Option: munin
local munin = additional_services:option(Flag, "munin", translate("Munin agent"),
translate("Munin agent (listening on port 4949) for monitorization and statistics purposes"))
munin.default=0

function m.on_commit(self,map)
	luci.sys.call('/etc/qmp/qmp_control.sh apply_services > /tmp/qmp_apply_services.log &')
	http.redirect("/luci-static/resources/qmp/wait_short.html")
end

return m
