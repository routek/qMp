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
--]]

model = require "qmp.model"
util = require "qmp.util"
debug = require "qmp.debug"
iwinfo = require "iwinfo"

wifi = {}
wifi.info = {}

function wifi.apply(dev)
	debug.set_namespace("WiFi")
	debug.logger(util.printf("Executing wifi.apply(%s)",dev))

	local index = model.get_indextype("wireless","device",dev)[1]
	local wdev = model.get_type("wireless",index)

	if wdev == nil then
		debug.logger(util.printf("Device %s cannot be found!",dev))
	end
	if wdev.mode == "none" then
		debug.logger("Device "..dev.." mode is none, qMp won't configure it")
		return true
	end

	debug.logger(util.printf("From model: index=%s wdev=%s",index,wdev))

	-- Getting all parameters and checking no one is nil
	local mode = wdev.mode
	local channel =  util.replace(wdev.channel,{'+','-'},'')
	local channel_mode = util.replace(wdev.channel,"[0-9]",'')
	local name = wdev.name
	local mac = wdev.mac
	local device = wdev.device
	
	if not (mode and channel and channel_mode and name and mac and device) then
		debug.logger("Some missing parameter, cannot apply")
		return false
	end

	local template = nil

	debug.logger("Channel is " .. channel)
	debug.logger("Channel mode is " .. channel_mode)

	-- chnanel_mode: HT40 = 10+/- | 802.11b = 10b | 802.11ag or HT20 = 10
	if channel_mode ~= "b" then
		if #channel_mode ~= 0 and wifi.info.modes(dev).n then
			template = mode .. "-n"
		else
			template = mode
		end
	else
		template = mode.."-b"
	end
	debug.logger("Selected template is " .. template)
end

function wifi.info.modes(dev)
        local modes = {}
        local iw = iwinfo[iwinfo.type(dev)]
        if iw ~= nil then modes = iw.hwmodelist(dev) end
        return modes
end


