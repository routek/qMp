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

bgp = {}

--- Get the published networks of the current node
-- @class function
-- @name get_networks
-- @return table
function bgp.get_networks()
	return model.get_type('bgp')	
end

--- Get the devices working on bpg mode
-- @class function
-- @name get_devices
-- @return	UCI value
function bgp.get_devices()
	return model.get('interfaces', 'bgp_devices')
end

--- Add a BGP peer
-- @class function
-- @name add_peer
-- @param as AS of the BGP peer
-- @param ip IP of the BGP peer
-- @param netmask Netmask of the BGP peer
-- @return	Name of created section
function bgp.add_peer(as, ip, netmask)
	return model.add_type('bgp', { as = 'as', ipdest = 'ip', netmask = 'netmask'})
end

--- Set the devices working on BGP mode
-- @class function
-- @name set_devices
-- @param devices Devices working on bgp mode (string)
-- @return	Boolean whether operation succeeded
function bgp.set_device(devices)
	return model.set('interfaces', 'bgp_devices', devices)	
end


--- Add a network to being published by BGP
-- @class function
-- @name add_network
-- @param network network range to be published
-- @return Boolean whether operation succeeded
function bgp.add_network(network)
	return model.set_list('bgp', 'network', network)
end

--- Remove the current BGP configuration 
-- @class function
-- @name clear
function bgp.clear()
	model.delete('bgp') 
	model.delete_type('bgp') 
	model.add('qmp', 'bgp')
	model.set('interfaces', 'bgp_devices', '')	
	model.add('qmp', 'bgp')
end

--- Set the AS of the working node
-- @class function
-- @name set_as
-- @param as AS of the working node 
-- @return	Boolean whether operation succeeded
function bgp.set_as(as)
	return model.set('bgp', 'as', as)
end

--- Get the AS of the working node
-- @class function
-- @name get_as
-- @return AS of the working node 
function bgp.get_as()
	return model.get('qmp', 'bgp', 'as')
end

return bgp
