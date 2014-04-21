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
--! @brief functions to configure and fetch information from bgp daemon

model = require "qmp.model"

bgp = {}

--! @brief Get the published networks of the current node
--! @return table
function bgp.get_networks()
	return model.get_type('bgp')
end

--! @brief Get the devices working on bpg mode
--! @return	UCI value
function bgp.get_devices()
	return model.get('interfaces', 'bgp_devices')
end

--! @brief Add a BGP peer
--! @param as AS of the BGP peer
--! @param ip IP of the BGP peer
--! @param netmask Netmask of the BGP peer
--! @return	Name of created section
function bgp.add_peer(as, ip, netmask)
	return model.add_type('bgp', { as = 'as', ipdest = 'ip', netmask = 'netmask'})
end

--! @brief Set the devices working on BGP mode
--! @param devices Devices working on bgp mode (string)
--! @return	Boolean whether operation succeeded
function bgp.set_device(devices)
	return model.set('interfaces', 'bgp_devices', devices)
end


--! @brief Add a network to being published by BGP
--! @param network network range to be published
--! @return Boolean whether operation succeeded
function bgp.add_network(network)
	return model.set_list('bgp', 'network', network)
end

--! @brief Remove the current BGP configuration
function bgp.clear()
	model.delete('bgp')
	model.delete_type('bgp')
	model.add('qmp', 'bgp')
	model.set('interfaces', 'bgp_devices', '')
	model.add('qmp', 'bgp')
end

--! @brief Set the AS of the working node
--! @param as AS of the working node
--! @return	Boolean whether operation succeeded
function bgp.set_as(as)
	return model.set('bgp', 'as', as)
end

--! @brief Get the AS of the working node
--! @return AS of the working node
function bgp.get_as()
	return model.get('qmp', 'bgp', 'as')
end

return bgp
