#!/usr/bin/lua
--[[
    Copyright (C) 2011 Fundacio Privada per a la Xarxa Oberta, Lliure i Neutral guifi.net
    Authors: Joel Espunya, Pau Escrich <p4u@dabax.net>
    
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
--! @brief control functions to manage the system

local bgp = require "qmp.bgp"
local model = require "qmp.model"
local util = require "luci.util"
control = {}

--! @brief Remove the current bgp configuration 
function control.remove_bgp_config()
	bgp.clear()
end

--! @brief Add a BGP peer 
--! @param as AS of the BGP peer (if doesn't exist, it should be given as an argument)
--! @param ip IP of the BGP peer  (if doesn't exist, it should be given as an argument)
--! @param netmask Netmask of the BGP peer  (if doesn't exist, it should be given as an argument)
--! @return	Boolean whether operation succeeded
function control.add_bgp_peer(as, ipdest, netmask)
	if not as or not ipdest or not netmask then
		if table.getn(arg) == 3 then
			as = arg[1]
			ipdest = arg[2]
			netmask = arg[3]
		else
			print('You should give the AS, ip and the netmask of peer you want to create as arguments or parameters')
			return false
		end
	else
		print('You should give the AS, ip and the netmask of peer you want to create as arguments or parameters')
		return false
	end 
			
	bgp.add_peer(as, ipdest, netmask)
	return true
end

--! @brief Add a network to being published by BGP
--! @param network network range to be published (if doesn't exist, it should be given as an argument)
--! @return Boolean whether operation succeeded
function control.add_bgp_network(range)
	if not range then
		if table.getn(arg) == 1 then
			range = arg[1]
		else 
			print('You should give the range of the network you want to publish as an argument or a parameter. Use the format: 10.1.1.0/24')
			return false
		end
	else
		print('You should give the range of the network you want to publish as an argument or a parameter. Use the format: 10.1.1.0/24')
		return false
	end
		
	bgp.add_network(range)
	return true
end

--! @brief Set the devices working on BGP mode
--! @param devices Devices working on bgp mode (if doesn't exist, it should be given as an argument)
--! @return	Boolean whether operation succeeded
function control.set_bgp_devices(devices)
	if not devices then 
		if table.getn(arg) == 1 then
			devices	= arg[1]
		else
			print('You should give the device you want to set on a bgp mode as an argument or a parameter')
			return false
		end
	else
		print('You should give the device you want to set on a bgp mode as an argument or a parameter')
		return false
	end

	bgp.set_device(devices)
	return true
end

--! @brief Set the AS of the working node
--! @param as AS of the working node (if doesn't exist, it should be given as an argument)
--! @return	Boolean whether operation succeeded
function control.set_bgp_as(as)
	if not as then 
		if table.getn(arg) == 1 then
			as = agv[1]
		else
			print('You should give the AS as an argument or a parameter')
			return false
		end
	else
		print('You should give the AS as an argument or a parameter')
		return false
	end

	bgp.set_as(as)
	return true
end

--! @brief Applies UCI configuration changes
function control.apply_changes()
	model.apply()
end

function control.configure_net_devices()
	print("Configuring network devices")
	local v,i,s
	local vlan_tags = {}
	local vids = model.get("networks","mesh_protocol_vids")
	local vid_offset = model.get("networks","mesh_vid_offset")
	
	for i,v in ipairs(util.split(vids," ")) do
		s = util.split(v,":")
		vlan_tags[s[1]] = vid_offset + s[2]
	end
	print("VLAN vids and protocols found")
	util.dumptable(vlan_tags)	
end

return control

