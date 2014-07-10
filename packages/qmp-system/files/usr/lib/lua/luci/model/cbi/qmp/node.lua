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

m = Map("qmp", "qMp node basic settings")

node_section = m:section(NamedSection, "node", "qmp", translate("Node identity"), translate("Use this page to define basic qMp settings, like the node\'s name."))
node_section.addremove = False

community_id = node_section:option(Value,"community_id", translate("Node name"), translate("The name for this node (use alphanumeric characters, without spaces)."))
community_id.default = "qMp"
community_id.datatype = "hostname"

primary_device = node_section:option(Value,"primary_device", translate("Primary network device"), translate("The name of the node's primary network device. The last four digits of this device's MAC address will be appended to the node name."))
primary_device.default = "eth0"
primary_device.datatype = "network"

geopos_lat = node_section:option(Value,"latitude", translate("Latitude"), translate("Latitude geoposition to use in the maps (optional)."))
geopos_lon = node_section:option(Value,"longitude", translate("Longitude"), translate("Longitude geoposition to use in the maps (optional)."))
geopos_elv = node_section:option(Value,"elevation", translate("Elevation"), translate("Elevation of the node relative to the ground level (optional)."))

contact = node_section:option(Value,"contact", translate("Contact e-mail"), translate("An e-mail to contact you if needed (optional)."))

function m.on_commit(self,map)
	http.redirect("/luci-static/resources/qmp/wait_short.html")
        luci.sys.exec('/etc/qmp/qmp_control.sh configure_system > /tmp/qmp_control_system.log &')
end


return m

