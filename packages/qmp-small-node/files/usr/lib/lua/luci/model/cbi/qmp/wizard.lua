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

local sys = require "luci.sys"
local uci  = require "luci.model.uci"
local http = require "luci.http"

package.path = package.path .. ";/etc/qmp/?.lua"
qmpinfo = require "qmpinfo"

m = SimpleForm("qmp_tmp", translate("qMp Wizard"))

netmode = m:field(ListValue, "_netmode",translate("Network mode"),translate("Roaming for quick deployments.<br/>Community for network communities"))
netmode:value("community","community")
netmode:value("roaming","roaming")
netmode.default="roaming"


nodename = m:field(Value, "_nodename", translate("Node name"),translate("The name of this node"))
nodename:depends("_netmode","community")

nodeip = m:field(Value, "_nodeip", translate("IP address"),translate("IP address to use as main IPv4 address"))
nodeip:depends("_netmode","community")

nodemask = m:field(Value, "_nodemask",translate("Network mask"),translate("Netmask to use with this IP"))
nodemask.default = "255.255.255.0"
nodemask:depends("_netmode","community")


--local htmlraw
--htmlraw = m:option(DummyValue)
--htmlraw.rawhtml = true
--htmlraw.default = "<h3>Network devices</h3>"

-- Get list of devices {{ethernet}{wireless}}
devices = qmpinfo.get_devices()

-- Ethernet devices
nodedevs_eth = {}

for i,v in ipairs(devices[1]) do
        tmp = m:field(ListValue, "_" .. v, v)
	tmp:value("Mesh")
	tmp:value("Lan")
	tmp:value("Wan")
	if v == "eth0" then
		tmp.default = "Lan"
	else
		tmp.default = "Wan"
	end
	nodedevs_eth[i] = {v,tmp}
end

-- Wireless devices
nodedevs_wifi = {}

for i,v in ipairs(devices[2]) do
	tmp = m:field(ListValue, "_" .. v, v)
	tmp:value("Mesh")
	tmp:value("AP")
	if v == "wlan1" then
		tmp.default = "AP"
	else
		tmp.default = "Mesh"
	end
	nodedevs_wifi[i] = {v,tmp}
end

function netmode.write(self, section, value)
	local uciout = uci.cursor()
	local name = nodename:formvalue(section)
	local mode = netmode:formvalue(section)
	local nodeip = nodeip:formvalue(section)
	local nodemask = nodemask:formvalue(section)

	if mode == "community" then
		uciout:set("qmp","non_overlapping","ignore","1")
		uciout:set("qmp","networks","publish_lan","1")
		uciout:set("qmp","networks","lan_address",nodeip)
		uciout:set("qmp","networks","bmx6_ipv4_address",nodeip)
		uciout:set("qmp","networks","lan_netmask",nodemask)

	else
		uciout:set("qmp","non_overlapping","ignore","0")
		uciout:set("qmp","networks","publish_lan","0")
		uciout:set("qmp","networks","lan_address","172.30.22.1")
		uciout:set("qmp","networks","lan_netmask","255.255.0.0")
		uciout:set("qmp","networks","bmx6_ipv4_prefix24","10.202")
		uciout:set("qmp","networks","bmx6_ipv4_address","")
		uciout:set("qmp","networks","olsr6_ipv4_address","")
		uciout:set("qmp","networks","olsr6_ipv4_prefix24","10.201")

	end
	
	local i,v,devmode,devname
	local lan_devices = ""
	local wan_devices = ""
	local mesh_devices = ""

	for i,v in ipairs(nodedevs_eth) do
		devmode = v[2]:formvalue(section)
		devname = v[1]

		if devmode == "Lan" then
			lan_devices = lan_devices..devname.." "
		elseif devmode == "Wan" then
			wan_devices = wan_devices..devname.." "
		elseif devmode == "Mesh" then
			mesh_devices = mesh_devices..devname.." "
		end	
	end

	for i,v in ipairs(nodedevs_wifi) do
		devmode = v[2]:formvalue(section)
		devname = v[1]
			
		if devmode == "AP" then
			lan_devices = lan_devices..devname.." "
		elseif devmode == "Mesh" then
			mesh_devices = mesh_devices..devname.." "
		end

		function setmode(s)
			if s.device == devname then
				if devmode == "AP" then uciout:set("qmp",s['.name'],"mode","ap") end
				if devmode == "Mesh" then uciout:set("qmp",s['.name'],"mode","adhoc") end
			end
		end
		uciout:foreach("qmp","wireless",setmode)
	end
	
	uciout:set("qmp","interfaces","lan_devices",lan_devices)
	uciout:set("qmp","interfaces","wan_devices",wan_devices)
	uciout:set("qmp","interfaces","mesh_devices",mesh_devices)

	uciout:commit("qmp")
	apply()
end

function apply(self)
	http.redirect("/luci-static/resources/qmp/wait.html")
        luci.sys.call('qmpcontrol configure_network >> /tmp/log/qmp_control_network.log &')
        luci.sys.call('qmpcontrol configure_wifi >> /tmp/log/qmp_control_wifi.log &')
end


return m
