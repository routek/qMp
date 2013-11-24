--[[
    Copyright (C) 2013 Quick Mesh Project

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
local uci = luci.model.uci.cursor()
local sys = require("luci.sys")

m = Map("gateways", "Quick Mesh Project")

-- GET GATEWAYS NAMES
gw_names = {}
uci:foreach('gateways','gateway', function (s)
            	local name = s[".name"]
            	if name ~= nil then
            		table.insert(gw_names,name)
            	end
            end)

gw_section = m:section(TypedSection, "gateway", "Gateways","Configuration of the network prefixes to search and to offer in the mesh.")
gw_section.addremove = true
gw_section.anonymous = false

-- DEFAULT PARAMETERS
type = gw_section:option(Value,"type", "type")
network = gw_section:option(Value,"network", "network")
ignore = gw_section:option(Value,"ignore", "ignore", "Ignore or enable this gateway rule (values: 0 or 1)")

-- OPTIONAL PARAMETERS (not using all BMX6 tun options)
local gwoptions = {
	{["name"]="address", ["help"]=""},
	{["name"]="gwName", ["help"]="hostname of remote tunnel endpoint"},
	{["name"]="minPrefixLen", ["help"]="minimum prefix length for accepting advertised tunnel network (value 129 = network prefix length)"},
	{["name"]="maxPrefixLen", ["help"]="maximum prefix length for accepting advertised tunnel network (value 129 = network prefix length)"},
	{["name"]="srcNet", ["help"]="additional source address range to be routed via tunnel ({NETWORK}/{PREFIX-LENGTH})"},
	{["name"]="srcType", ["help"]="tunnel ip allocation mechanism (0 = static/global, 1 = static, 2 = auto, 3 = AHCP)"},
	{["name"]="bandwidth", ["help"]="network bandwidth (bits/sec) (default: 1000, range: [36..128849018880])"},
	{["name"]="minBandwidth", ["help"]="minimum bandwidth (bits/sec) beyond which GW's advertised bandwidth is ignored (default: 100000, range: [36..128849018880])"},
	{["name"]="tunDev", ["help"]="incoming tunnel interface name to be used"},
	{["name"]="exportDistance", ["help"]=""},
	{["name"]="allowOverlappingPrefix", ["help"]="allow overlapping other tunRoutes with worse tunMetric but larger prefix length"},
	{["name"]="breakOverlappingPrefix", ["help"]="let this tunRoute break other tunRoutes with better tunMetric but smaller prefix length"},
	{["name"]="tableRule", ["help"]="ip rules tabel and preference to maintain matching tunnels ({PREF}/{TABLE})"},
	{["name"]="ipMetric", ["help"]="ip metric for local routing table entries"},
	{["name"]="bonus", ["help"]="specify in percent a metric bonus (preference) for GWs matching this tunOut spec when compared with other tunOut specs for same network"},
	{["name"]="hysteresis", ["help"]="specify in percent how much the metric to an alternative GW must be better than current GW"}
}

for _,o in ipairs(gwoptions) do
	if o.name ~= nil then
		value = gw_section:option(Value, o.name, o.name, o.help)
		value.optional = true
	end
end


function m.on_commit(self,map)
	http.redirect("/luci-static/resources/qmp/wait_short.html")
	luci.sys.call('/etc/qmp/qmp_control.sh configure_gw > /tmp/qmp_control_system.log &')
end


return m

