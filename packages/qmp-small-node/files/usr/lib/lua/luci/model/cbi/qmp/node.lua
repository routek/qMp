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

m = Map("qmp", "Quick Mesh Project")

node_section = m:section(NamedSection, "node", "qmp", translate("Node"), translate("Node configuration options"))
node_section.addremove = False

community_id = node_section:option(Value,"community_id", translate("Community id"), translate("Community identifier for node name (alphanumeric, no spaces)"))
community_node_id = node_section:option(Value,"community_node_id", translate("Node id"), translate("Node identifier, leave blank for randomize (hexadecimal 16bit)"))
primary_device = node_section:option(Value,"primary_device", translate("Primary device"), translate("Network primary device which never will change"))


function m.on_commit(self,map)
	http.redirect("/luci-static/resources/qmp/wait_short.html")
        luci.sys.call('/etc/qmp/qmp_control.sh configure_system > /tmp/qmp_control_system.log &')
end


return m

