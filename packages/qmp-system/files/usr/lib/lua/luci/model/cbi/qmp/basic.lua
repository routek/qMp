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
local uciout = uci.cursor()

m = Map("qmp", "Basic qMp device settings")

local networkmode
if uciout:get("qmp","roaming","ignore") == "1" then
	networkmode="community"
else
	networkmode="roaming"
end


device_section = m:section(NamedSection, "node", "qmp", translate("Device identity"), translate("Use this page to define basic qMp settings, like the device\'s name, etc."))
device_section.addremove = False

if networkmode == "community" then
	community_name = device_section:option(Value, "community_name", translate ("Community Network name"), translate("Select a predefined Community Network or type your own name."))
	community_name.datatype="string"
	community_name:value("Bogotá Mesh","Bogotá Mesh")
	community_name:value("DigitalMerthyr","Digital Merthyr")
	community_name:value("Guifi.net","Guifi.net")
	
	guifimesh_name = device_section:option(Value, "mesh_name", translate ("Mesh Network name"), translate("Select a predefined Mesh Network or type your own name."))
	guifimesh_name:depends("community_name","Guifi.net")
	guifimesh_name.datatype="string"
	guifimesh_name:value("GuifiBaix", "Baix Llobregat (GB)")
	guifimesh_name:value("Bellvitge", "Bellvitge")
	guifimesh_name:value("GraciaSenseFils", "Gràcia Sense Fils (GSF)")
	guifimesh_name:value("PoblenouSenseFils", "Poblenou Sense Fils (P9SF)")
	guifimesh_name:value("Quesa", "Quesa (QUESA)")
	guifimesh_name:value("Raval", "Raval (GuifiBaix)")
	guifimesh_name:value("GuifiSants", "Sants-Les Corts-UPC (GS)")
	guifimesh_name:value("SantAndreu", "Sant Andreu (SAND)")
	guifimesh_name:value("Vallcarca", "Vallcarca (VKK)")
end

device_name = device_section:option(Value,"device_name", translate("Device name"), translate("The name for this device (use alphanumeric characters, without spaces)."))
device_name.default = "qMp"
device_name.datatype = "hostname"
device_name.optional = false

device_id = device_section:option(Value,"device_id", translate("Device id"), translate("The id of this device in the mesh network (use alphanumeric characters, without spaces)."))
device_id.datatype = "string"
device_id.optional = true

primary_device = device_section:option(Value,"primary_device", translate("Primary network device"), translate("The name of the node's primary network device. The last four digits of this device's MAC address will be appended to the node name."))
primary_device.default = "eth0"
primary_device.datatype = "network"

location_section = m:section(NamedSection, "node", "qmp", translate("Device location"))
location_section.addremove = False

geopos_lat = location_section:option(Value,"latitude", translate("Latitude"), translate("Latitude geoposition to use in the maps (optional)."))
geopos_lon = location_section:option(Value,"longitude", translate("Longitude"), translate("Longitude geoposition to use in the maps (optional)."))
geopos_elv = location_section:option(Value,"elevation", translate("Elevation"), translate("Elevation of the node relative to the ground level (optional)."))


contact_section = m:section(NamedSection, "node", "qmp", translate("Contact information"))
contact_section.addremove = False

contact = contact_section:option(Value,"contact", translate("Contact e-mail"), translate("An e-mail to contact you if needed (optional)."))

function m.on_commit(self,map)
	http.redirect("/luci-static/resources/qmp/wait_short.html")
        luci.sys.exec('/etc/qmp/qmp_control.sh configure_system > /tmp/qmp_control_system.log &')
end


return m

