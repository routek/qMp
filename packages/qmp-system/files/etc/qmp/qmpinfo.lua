#!/usr/bin/lua
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

    Contributors:
        Simó Albert i Beltran

--]]

local iwinfo = require "iwinfo"
local util = require "luci.util"
local sys = require "luci.sys"
local nixio = require "nixio"
local uci = luci.model.uci.cursor()
local qmpinfo = {}
local i,d


local function tableConcat(t1,t2)
	local _,i
	for _,i in ipairs(t2) do
		table.insert(t1,i)
	end
	return t1
end

local function isInTable(t,e)
	local yes = false
	local _,i
	for _,i in ipairs(t) do
		if i == e then
			yes = true
			break
		end
	end
	return yes
end

local function printr(t)
	local _,i
	for _,i in ipairs(t) do
		print(" " .. tostring(_) .. " -> " .. tostring(i))
	end	
end

function qmpinfo.get_qmp_devices()
	local devs = {}
	local mesh = util.split( uci:get("qmp","interfaces","mesh_devices") or ""," ")
	local lan = util.split(uci:get("qmp","interfaces","lan_devices") or ""," ")
	local wan = util.split(uci:get("qmp","interfaces","wan_devices")or "", " ")
	tableConcat(devs,mesh)
	tableConcat(devs,lan)
	tableConcat(devs,wan)
	return devs
end

-- returns all the physical devices as a table
--  in table.wifi only the wifi ones
--  in table.eth only the non-wifi ones

function qmpinfo.get_devices()
	local d
	local phydevs = {}
	phydevs.wifi = {}
	phydevs.all = {}
	phydevs.eth = {}
	local ignored = util.split( uci:get("qmp","interfaces","ignore_devices") or ""," ")
	
--	uci:foreach('network','switch_vlan', function (s)
--			local name = uci:get("network",s[".name"],"device")
--			local vlan = uci:get("network",s[".name"],"vid")
--			if name ~= nil and vlan ~= nil then
--				table.insert(phydevs.eth,name..'.'..vlan)
--				table.insert(phydevs.all,name..'.'..vlan) 
--				table.insert(ignored,name)
--			end
--		end)

	local sysnet = "/sys/class/net/"
	local qmp_devs = qmpinfo.get_qmp_devices()
	
	for d in nixio.fs.dir(sysnet) do
		local is_qmp_dev = isInTable(qmp_devs,d)
		if is_qmp_dev or nixio.fs.stat(sysnet..d..'/device',"type") ~= nil then 
			if is_qmp_dev or (string.find(d,"%.") == nil and string.find(d,"ap") == nil) then
				local ignore = isInTable(ignored,d)
				
				if not ignore then
					if nixio.fs.stat(sysnet..d..'/phy80211',"type") ~= nil then
						table.insert(phydevs.wifi,d)
					else
						table.insert(phydevs.eth,d) 
					end
					table.insert(phydevs.all,d) 
				end
			end
		end
	end

	return phydevs
end

-- deprecated	
function qmpinfo.get_devices_old()

	ethernet_interfaces = { 'eth' }
	wireless_interfaces = { 'ath', 'wlan' }

	local eth_int = {}
	for i,d in ipairs(sys.net.devices()) do
		for i,r in ipairs(ethernet_interfaces) do
			if string.find(d,r) ~= nil then
				if string.find(d,"%.") == nil  then
					table.insert(eth_int,d)
				end
			end
		end
	end

	local wl_int = {}
	for i,d in ipairs(luci.sys.net.devices()) do
		for i,r in ipairs(wireless_interfaces) do
			if string.find(d,r) ~= nil then
				if string.find(d,"%.") == nil  then
					table.insert(wl_int,d)
				end
			end
		end
	end

	return {eth_int,wl_int}

end

function qmpinfo.get_modes(dev)
	local modes = {}
	local iw = iwinfo[iwinfo.type(dev)]
	if iw ~= nil then modes = iw.hwmodelist(dev) end
	return modes

end


function qmpinfo.get_txpower(dev)
	local iw = iwinfo[iwinfo.type(dev)]
	local txpower_supported = {}
	if iw ~= nil then
		local txp = iw.txpwrlist(dev) or {}
		for _,v in ipairs(txp) do
			table.insert(txpower_supported,v.dbm)
		end
	end

	return txpower_supported

end

function qmpinfo.get_channels(dev)
	local clist = {} -- output channel list
	local iw = iwinfo[iwinfo.type(dev)]
	local ch = {}

	-- if there are not wireless cards, returning a dummy value
	if iw == nil then
		ch.channel=0
		ch.adhoc=false
		ch.ht40p=false
		ch.ht40m=false
		table.insert(clist,ch)
		return clist
	end

	local freqs = iw.freqlist(dev) --freqs list
	local c -- current channel
	local nc = 0 -- next channel
	local pc = 0 -- previous channel
	local adhoc
	local ht40_support = qmpinfo.get_modes(dev).n


	for i,f in ipairs(freqs) do
		c = f.channel
		ch = {}
		ch.channel = c
		ch.ht40p = false
		ch.ht40m = false

		if not f.restricted then
			ch.adhoc = true
		else
			ch.adhoc = false
		end

		-- 2.4Ghz band
		if c < 15 then
			if c < 4 then
				ch.ht40p = true

			elseif c < 10 then
				ch.ht40m = true
				ch.ht40p = true
			else
				ch.ht40m = true
			end

		-- 5Ghz band
		elseif c > 14 then
			if #freqs == i then nc = nil
			else nc = freqs[i+1].channel
			end

			if i == 1 then pc = nil
			else pc = freqs[i-1].channel
			end

			if nc ~= nil and nc-c == 4 then
				ch.ht40p = true
			end

			if pc ~= nil and c-pc == 4 then
				ch.ht40m = true
			end

		end

		-- If the device does not support ht40, both vars (+/-) are false
		if not ht40_support then
			ch.ht40p = false
			ch.ht40m = false
		end

		table.insert(clist,ch)

	end
	return clist
end


function qmpinfo.get_ipv4()
	local ipv4 = {}
	local ipv4_raw = util.exec("ip -4 a | awk '/inet/{print $2}'")
	for _,v in ipairs(util.split(ipv4_raw)) do
		local match = false
		local i = 1
		while i <= #ipv4 and not match do
			match = string.match(util.trim(v),util.trim(ipv4[i]))
			i = i + 1
		end
		if not match and #util.trim(v) > 1 then
			table.insert(ipv4,util.trim(v))
		end
	end
	return ipv4
end

function qmpinfo.get_hostname()
	local hostname = util.exec("cat /proc/sys/kernel/hostname")
	return hostname
end

function qmpinfo.get_uname()
	local uname = util.exec("uname -a")
	return uname
end

function qmpinfo.bandwidth_test(ip)
        local bwtest = util.trim(util.exec("netperf -6 -p 12865 -H "..ip.." -fm -v0 -P0"))
        local result = nil
        if #bwtest < 10 then
                result = bwtest
        end

        return result
end

function qmpinfo.get_wifi_index()
	local k,v
	local windex = {}
	for k,v in pairs(uci:get_all("qmp")) do
			if v.device ~= nil and v.mac ~= nil then
				table.insert(windex,k)
			end
	end
	
	return windex
end

function qmpinfo.nodes()
	local nodes = util.split(util.exec('bmx6 -c --originators | awk \'{print $1 "|" $3}\' | grep -e ".*:.*:"'))
	local ni
	result = {}
	for _,n in ipairs(nodes) do
		if n ~= "" then
		 ni = util.split(n,"|")
		 ni[1] = util.split(ni[1],".")[1]
		 table.insert(result,ni)
		end
	end
	return result
end

function qmpinfo.links()
	local nodes = util.split(util.exec('bmx6 -c --links | awk \'{print $1 "|" $2}\' |  grep -e ".*:.*:"'))
	local ni
	result = {}
	for _,n in ipairs(nodes) do
		if n ~= "" then
		ni = util.split(n,"|")
		ni[1] = util.split(ni[1],".")[1]
		table.insert(result,ni)
		end
	end
	return result
end

function qmpinfo.get_version(option)                    
	local version = nil
	if option == nil or option == "full" then version = util.exec("cat /etc/qmp/qmp.release | grep DESCRIPTION | cut -d= -f2")
	elseif option == "build" then version = util.exec("cat /etc/qmp/qmp.release | grep BUILDDATE | cut -d= -f2")
	elseif option == "branch" then version = util.exec("cat /etc/qmp/qmp.release | grep BRANCH | cut -d= -f2")
	elseif option == "codename" then version = util.exec("cat /etc/qmp/qmp.release | grep CODENAME | cut -d= -f2")
	elseif option == "release" then version = util.exec("cat /etc/qmp/qmp.release | grep RELEASE | cut -d= -f2")
	elseif option == "revision" then version = util.exec("cat /etc/qmp/qmp.release | grep REVISION | cut -d= -f2")
	else version = nil
	end
	return version
end  

function qmpinfo.get_key()
	local keyf = util.exec("uci get qmp.node.key")
	if #keyf < 2 then
		keyf = "/tmp/qmp_key"
	end
	local key = util.split(util.exec("cat "..keyf))[1]
	return key
end

return qmpinfo

