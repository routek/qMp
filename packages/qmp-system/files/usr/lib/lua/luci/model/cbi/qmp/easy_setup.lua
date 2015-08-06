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
local http = require "luci.http"
local ip = require "luci.ip"
local util = require "luci.util"
local uci  = require "luci.model.uci"
local uciout = uci.cursor()

package.path = package.path .. ";/etc/qmp/?.lua"
qmpinfo = require "qmpinfo"

m = SimpleForm("qmp", translate("qMp easy setup"),translate("This page provides a fast and simple way to configure the basic settings of a qMp node.").." "..translate("Use the fields below to specify the network mode, the IP addressing and the interface modes."))

local mode_help
mode_help = m:field(DummyValue,"mode_help")
mode_help.rawhtml = true
mode_help.default = "<strong>"..translate("Network mode").."</strong>".."<br/> <br/>"..translate("qMp nodes can operate in two different modes, depending on the kind of network to deploy.").." "..translate("According to your needs, you can choose between")..":<br/> <br/> · "..translate("roaming mode, for quick, temporal deployments. User devices connected to the network can roam between Access Points without loosing connectivity. However, they can not see other devices connected to the Mesh.").."<br/> · "..translate("community mode for static, long-term deployments (such as community networks). User devices connected to the network get an IP address from a specific range and are accessible from the rest of the Mesh. However, roaming between stations is not possible.").."<br/> <br/>"

netmode = m:field(ListValue, "_netmode","<strong>"..translate(" ").."</strong>",translate("\"Roaming\" mode for quick, temporal network setups. \"Community\" mode for community networks and long-term deployments."))
netmode:value("community","community")
netmode:value("roaming","roaming")

local networkmode
if uciout:get("qmp","roaming","ignore") == "1" then
	local ipv4 = uciout:get("qmp","networks","bmx6_ipv4_address")
	local ipv4mask = string.find(ipv4,"/")
	if ipv4mask ~= nil then
		ipv4 = string.sub(ipv4,1,ipv4mask-1)
	end
	if ipv4 == uciout:get("qmp","networks","lan_address") then
		networkmode="community"
	end
else
	networkmode="roaming"
end
netmode.default=networkmode

local roaming_ipaddress_help
roaming_ipaddress_help = m:field(DummyValue,"roaming_ipaddress_help")
roaming_ipaddress_help.rawhtml = true
roaming_ipaddress_help:depends("_netmode","roaming")
roaming_ipaddress_help.default = "<strong>"..translate("IP address").."</strong>".."<br/> <br/>"..translate("Specify here an IP address for this node.").." "..translate("In roaming mode, all qMp nodes in a mesh network need a unique IPv4 address.").." "..translate("If unsure about which one to select, leave the field blank and a random one will be assigned automatically.").."<br/> <br/>"


local nodeip_roaming =  m:field(Value, "_nodeip_roaming", " ",
translate("Main IPv4 address for this node.").." "..translate("Leave it blank to get a random one."))
nodeip_roaming:depends("_netmode","roaming")


local rip = uciout:get("qmp","networks","bmx6_ipv4_address")
if rip == nil or #rip < 7 then
	rip = uciout:get("bmx6","general","tun4Address")
	if rip == nil or #rip < 7 then
		rip = ""
	end
end

nodeip_roaming.default=rip
nodeip_roaming.datatype="ip4prefix"

local community_name_help
community_name_help = m:field(DummyValue,"community_name_help")
community_name_help.rawhtml = true
community_name_help:depends("_netmode","community")
community_name_help.default = "<strong>"..translate("Node name").."</strong>".."<br/> <br/>"..translate("Choose a name for this node. It will be used to identify the device in the network. Use only alphanumeric characters, spaces are not allowed.").."<br/> <br/>"

local nodename = m:field(Value, "_nodename", " ",
translate("The name of this node. Four hex numbers will be appended, according the the device's MAC address."))

nodename:depends("_netmode","community")
nodename.default="qMp"
nodename.datatype="hostname"
if uciout:get("qmp","node","community_id") ~= nil then
	nodename.default=uciout:get("qmp","node","community_id")
end

local community_addressing_help
community_addressing_help = m:field(DummyValue,"community_addressing_help")
community_addressing_help.rawhtml = true
community_addressing_help:depends("_netmode","community")
community_addressing_help.default = "<strong>"..translate("IP address and network mask").."</strong>".."<br/> <br/>"..translate("Specify the IP address and the network mask for this node, according to the planification of your community or your network deployment.").." "..translate("End-user devices will get an IP address within the valid range determined by these two values.").."<br/> <br/>"


local nodeip = m:field(Value, "_nodeip", " ",
translate("Main IPv4 address for this node."))

nodeip:depends("_netmode","community")
nodeip.default = "10.30."..util.trim(util.exec("echo $((($(date +%M)*$(date +%S)%254)+1))"))..".1"
nodeip.datatype="ip4addr"

local nodemask = m:field(Value, "_nodemask"," ",
translate("Network mask to be used with the IPv4 address above."))
nodemask:depends("_netmode","community")
nodemask.default = "255.255.255.0"
nodemask.datatype="ip4addr"

local interface_mode_help
interface_mode_help = m:field(DummyValue,"interface_mode_help")
interface_mode_help.rawhtml = true
interface_mode_help.default = "<strong>"..translate("Interface modes").."</strong>".."<br/> <br/>"..translate("Select the working mode of the network interfaces")..":<br/> <br/> · "..translate("LAN mode is used to provide connectivity to end-users (a DHCP server will be enabled to assign IP addresses to the devices connecting)").."<br/> · "..translate("WAN mode is used on interfaces connected to an Internet up-link or any other gateway connection").."<br/> · "..translate("Mesh mode is used on wireless interfaces to join the qMp mesh and, on wired interfaces, to link with other qMp nodes").."<br/> · "..translate("AP mode is used on wireless interfaces to act as an access point and provide connectivity to end-users").."<br/> <br/>"

if networkmode == "community" then
	nodeip.default=uciout:get("qmp","networks","lan_address")
	nodemask.default=uciout:get("qmp","networks","lan_netmask")
end

-- Get list of devices {{ethernet}{wireless}}
devices = qmpinfo.get_devices()

-- Ethernet devices
nodedevs_eth = {}

local function is_a(dev, what)
	local x
	for x in util.imatch(uciout:get("qmp", "interfaces", what)) do
        	if dev == x then
        		return true
        	end
        end
	return false
end

for i,v in ipairs(devices.eth) do
		tmp = m:field(ListValue, "_" .. v, translatef("Wired interface <strong>%s</strong>",v))
	tmp:value("Mesh")
	tmp:value("Lan")
	tmp:value("Wan")

	if is_a(v, "lan_devices") then
		tmp.default = "Lan"
	elseif is_a(v, "wan_devices") then
		tmp.default = "Wan"
	elseif is_a(v, "mesh_devices") then
		tmp.default = "Mesh"
	end

	nodedevs_eth[i] = {v,tmp}
end

-- MeshAll option for wired devices

meshall = m:field(Flag, "_meshall", translate("Use mesh in all wired devices"),translate("If this option is enabled, all the wired network devices will be used for meshing"))
meshall.default = "0"

-- Wireless devices
nodedevs_wifi = {}

for i,v in ipairs(devices.wifi) do
		tmp = m:field(ListValue, "_" .. v, translatef("Wireless interface <strong>%s</strong>",v))
	tmp:value("adhoc_ap","Ad hoc (mesh) + access point (LAN)")
    tmp:value("adhoc","Ad hoc (mesh)")
    tmp:value("ap","Access point (mesh)")
    tmp:value("aplan","Access point (LAN)")
    tmp:value("client","Client (mesh)")
    tmp:value("clientwan","Client (WAN)")
    tmp:value("80211s","[EXPERIMENTAL] 802.11s (mesh)")
    tmp:value("80211s_aplan","[EXPERIMENTAL] 802.11s (mesh) + access point (LAN)")

    tmp:value("none","Disabled")

	tmp.default = "adhoc_ap"

	-- Check if the device is adhoc_ap mode, then Mode=AP MeshAll=1
	uciout:foreach("qmp","wireless", function (s)
		if s.device == v then
			if s.mode ~= nil then
				tmp.default = s.mode
			end
		end
	end)

	nodedevs_wifi[i] = {v,tmp}
end



function netmode.write(self, section, value)
	local name = nodename:formvalue(section)
	local mode = netmode:formvalue(section)
	local nodeip = nodeip:formvalue(section)
	local nodemask = nodemask:formvalue(section)
	local nodeip_roaming = nodeip_roaming:formvalue(section)

	if mode == "community" then
		uciout:set("qmp","roaming","ignore","1")
		uciout:set("qmp","networks","publish_lan","1")
		uciout:set("qmp","networks","lan_address",nodeip)
		uciout:set("qmp","networks","bmx6_ipv4_address",ip.IPv4(nodeip,nodemask):string())
		uciout:set("qmp","networks","lan_netmask",nodemask)
		uciout:set("qmp","node","community_id",name)

	else
		uciout:set("qmp","roaming","ignore","0")
		uciout:set("qmp","networks","publish_lan","0")
		uciout:set("qmp","networks","lan_address","172.30.22.1")
		uciout:set("qmp","networks","lan_netmask","255.255.0.0")
		uciout:set("qmp","networks","bmx6_ipv4_prefix24","10.202.0")
		uciout:set("qmp","networks","olsr6_ipv4_address","")
		uciout:set("qmp","networks","olsr6_ipv4_prefix24","10.201")
		if nodeip_roaming == nil then
			uciout:set("qmp","networks","bmx6_ipv4_address","")
		else
			uciout:set("qmp","networks","bmx6_ipv4_address",nodeip_roaming)
		end

	end

	local i,v,devmode,devname
	local lan_devices = ""
	local wan_devices = ""
	local mesh_devices = ""
	local meshall = meshall:formvalue(section)

	for i,v in ipairs(nodedevs_eth) do
		devmode = v[2]:formvalue(section)
		devname = v[1]

		if devmode == "Lan" then
			lan_devices = lan_devices..devname.." "
		elseif devmode == "Wan" then
			wan_devices = wan_devices..devname.." "
		end
		if devmode == "Mesh" or meshall == "1" then
			mesh_devices = mesh_devices..devname.." "
		end
	end

	for i,v in ipairs(nodedevs_wifi) do
		devmode = v[2]:formvalue(section)
		devname = v[1]

		if (devmode == "AP" and meshall == "1") or devmode == "Mesh" then
			mesh_devices = mesh_devices..devname.." "
		elseif devmode == "AP" and meshall ~= "1" then
			lan_devices = lan_devices..devname.." "
		end

		function setmode(s)
			if s.device == devname then
				uciout:set("qmp",s['.name'],"mode",devmode)
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
	http.redirect("/luci-static/resources/qmp/wait_long.html")
        luci.sys.call('(qmpcontrol configure_wifi ; qmpcontrol configure_network) &')
end


return m
