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

iwinfo = require "iwinfo"

qmpinfo = {}

function qmpinfo.get_modes(dev)
	local iw = iwinfo[iwinfo.type(dev)]
	local ma = "" -- modes avaiable
	return iw.hwmodelist(dev)
	
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
		ch.adhoc = false

		-- 2.4Ghz band
		if c < 15 then
			if c < 4 then 
				ch.ht40p = true
				ch.adhoc = true 
			
			elseif c < 10 then 
				ch.ht40m = true  
				ch.ht40p = true
				ch.adhoc = true
			else 
				ch.ht40m = true
				ch.adhoc = true
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

			adhoc = os.execute("iw list | grep \"no IBSS\" | grep -v disabled | grep -q " .. f.mhz .. " 2>/dev/null")
			if adhoc ~= 0 then
				ch.adhoc = true
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

return qmpinfo
