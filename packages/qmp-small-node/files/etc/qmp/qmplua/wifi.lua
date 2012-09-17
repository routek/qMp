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
	local wdev = model.get_type_by_option('wireless','device',dev)
	if wdev.mode == "none" then
		debug.logger("Device "..dev.." mode is none, qMp wont configure it")	
		return true
	end
		
	-- Getting all parameters and checking no one is nil
	local mode = wdev.mode || return nil
	local channel =  util.replace(wdev.channel,'',('+','-')) || return nil
	local channel_mode = util.replace(wdev.channel,'',"[0-9]") || return nil
	local name = wdev.name || return nil
	local mac = wdev.mac || return nil
	local device = wdev.device || return nil

	local template = nil

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
	
end

function wifi.info.modes(dev)
        local modes = {}
        local iw = iwinfo[iwinfo.type(dev)]
        if iw ~= nil then modes = iw.hwmodelist(dev) end
        return modes
end



