#!/usr/bin/lua
--[[
    Copyright (C) 2011 Fundacio Privada per a la Xarxa Oberta, Lliure i Neutral guifi.net
    Authors: Pau Escrich <p4u@dabax.net>
    
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

--! @file
--! @brief wifi functions

model = require "qmp.model"
util = require "qmp.util"
debug = require "qmp.debug"
iwinfo = require "iwinfo"

wifi = {}
wifi.info = {}
wifi.template = {}

--! directory of UCI templates
local _TEMPLATES_DIR="/etc/qmp/templates/wifi"

--! @brief Applies the current WiFi configuration to the system
--! @param dev device to apply
--! return success or not
function wifi.apply(dev)
	debug.set_namespace("WiFi")
	debug.logger(util.printf("Executing wifi.apply(%s)",dev))
	
	wdev,msg = wifi.info.config(dev)
	if not wdev then
		if msg == "Device configured as none" then
			debug.logger("Device "..dev.." mode is none, qMp won't configure it")
			return true
		else
			debug.logger(msg)
			return false
		end
	end

	debug.logger(util.printf("Mode: %s | Channel: %s | Channel mode: %s | Country: %s | BSSID: %s | ESSID: %s | TXpower: %s | MAC: %s",wdev.mode,wdev.channel,wdev.channel_mode,wdev.country,wdev.bssid,wdev.name,wdev.txpower,wdev.mac))
		
	local device = wifi.template.device(wdev)
	local iface = wifi.template.iface(wdev)
	if not (device and iface) then
		debug.logger("Cannot get device/iface template information")
		return false
	end

end

--! @brief selects the template file to be used for the wifi-dev
--! @param wdev the wifi-device
--! @returns an array (device and iface). First is the virtual device template and second the physical iface template
function wifi.template.filename(wdev)
	-- chnanel_mode: HT40 = 10+/- | 802.11b = 10b | 802.11ag or HT20 = 10
	-- mode = adhoc | ap | client
	local template = {}

	if wdev.channel_mode ~= "b" then
		if  wifi.info.modes(wdev.device).n then
			template.device = "device."..wdev.driver .. "-n"
		else
			template.device = "device."..wdev.driver
		end
	else
		template.device = "device."..wdev.driver.."-b"
	end

	template.iface = "iface."..wdev.mode
	debug.logger("Selected template is: " .. template.device .. " | " .. template.iface)

	return template
end

function wifi.template.device(wdev)
	local template = wifi.template.filename(wdev).device
	local st,fd = pcall(io.open,_TEMPLATES_DIR.."/"..template,"r")
	if not st then
		debug.logger("Cannot open file ".._TEMPLATES_DIR.."/"..template)
		return false
	end
	local t = fd:read("*all")
	fd:close()
	
	if #wdev.channel > 0 then t = util.replace(t,'#QMP_CHANNEL',wdev.channel) end
	if #wdev.txpower > 0 then t = util.replace(t,'#QMP_TXPOWER',wdev.txpower) end
	t = util.replace(t,'#QMP_MAC',wdev.mac)
	t = util.replace(t,'#QMP_COUNTRY',wdev.country)
	t = util.replace(t,'#QMP_DEVICE',wdev.device)
	
	if wdev.channel_mode == 'b' then
		t = util.replace(t,'#QMP_HWMODE','11b')
	else
		t = util.replace(t,'#QMP_HWMODE','auto')
		local ht
		if wifi.info.modes(wdev.device).n then
			if wdev.channel_mode == "+" or wdev.channel_mode == "-" then
				ht = "40"
			else
				ht = "20"
			end
			t = util.replace(t,'#QMP_HTMODE','ht'..ht..wdev.channel_mode)
			t = util.replace(t,'#QMP_HT',ht)
		end
	end

	if util.find(t,'#QMP_') then
		debug.logger("CRITICAL: udefined template word which start with #QMP_ but it is not reconigzed")
		return false
	end

	return t
end

function wifi.template.iface(wdev)
	local template = wifi.template.filename(wdev).iface
	local st,fd = pcall(io.open,_TEMPLATES_DIR.."/"..template,"r")
	if not st then
		debug.logger("Cannot open file ".._TEMPLATES_DIR.."/"..template)
		return false
	end
	local t = fd:read("*all")
	fd:close()

	t = util.replace(t,'#QMP_DEVICE',wdev.device)
	t = util.replace(t,'#QMP_SSID',wdev.name)
	t = util.replace(t,'#QMP_BSSID',wdev.bssid)

	if util.find(t,'#QMP_') then
		debug.logger("CRITICAL: udefined template word which start with #QMP_ but it is not reconigzed")
		return false
	end

	return t
end	

function wifi.info.config(dev)
	local index = model.get_indextype("wireless","device",dev)[1]
	if index == nil then
		return false,"Device not found"
	end

	local wdev = model.get_type("wireless",index)
	if wdev == nil then
		return false,"Device not found"
	end

	if wdev.mode == "none" then
		return false,"Device configured as none"
	end

	local devconfig = {}

	-- Getting all parameters and checking no one is nil
	devconfig.driver = model.get("wireless","driver") or "nil"
	devconfig.bssid = model.get("wireless","bssid") or "nil"
	devconfig.country = model.get("wireless","country") or "nil"
	devconfig.mode = wdev.mode or "nil"
	devconfig.channel = util.replace(wdev.channel,{'+','-'},'') or "nil"
	devconfig.channel_mode = util.replace(wdev.channel,"[0-9]",'') or ""
	devconfig.name = wdev.name or "nil"
	devconfig.mac = wdev.mac or "nil"
	devconfig.txpower = wdev.txpower or ""
	devconfig.device = wdev.device or "nil"

	local i,v
	for i,v in pairs(devconfig) do 
		if v == "nil" then 
			return false,"missing parameter "..i.." in device configuration"
		end 
	end

	return devconfig,""

end

function wifi.info.modes(dev)
        local modes = {}
        local iw = iwinfo[iwinfo.type(dev)]
        if iw ~= nil then modes = iw.hwmodelist(dev) end
        return modes
end


