#!/usr/bin/luapplies UCI configuration changes
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

local socket = require("socket")

quagga = {}

--- Get the port used to connect to vtsyh for a given routing protocol enabled on quagga
-- @class function
-- @name get_vtsyh_port
-- @param type Name of a routing protocol
-- @return port for a vtsyh connection 
function quagga.get_vtsyh_port(type)
	if type == 'bgp' then
		return 2605
	end
end

--- Get a vtsyh connnection 
-- @class function
-- @name connect
-- @param type Name of a routing protocol
-- @param password Password to login on vtsyh
-- @param host IP address for the connecton [Default value: 127.0.0.1](optional)
-- @param port Port for the connection (optional) 
-- @timeout timeout The time where the connecton will expire [Default value: 2] (optional)
-- @return	Boolean whether operation succeeded
function quagga.connect(type, password, host, port, timeout)
	if type and password then
		port = port or quagga.get_vtsyh_port(type)
		host = host or '127.0.0.1'
		timeout = timeout or 2
		quagga.connection = assert(socket.connect(host, port))
		quagga.connection:settimeout(timeout)

		local l = quagga.connection:receive('*l') 
		while not string.find(l, 'Password:') do
			l = quagga.connection:receive('*l') 
		end
		assert(quagga.connection:send(password .. "\n"))

		local prompt = ''
		l = quagga.connection:receive('*l') 
		while not string.find(l, '>') do
			prompt = prompt .. " " .. l
			l = quagga.connection:receive('*l') 
		end

		if string.find(prompt, 'Password:') then 
			return false	
		else
			return true
		end 
	else
		return false
	end
end

--- Execute a Quagga command using the vtsyh console
-- @class function
-- @name command
-- @param command vtsyh command
-- @param command connection to a vtsyh console
-- @return	Boolean whether operation succeeded
function quagga.command(command)
	if quagga.connection then 
		assert(quagga.connection:send(command .. "\n"))
		return true
	else 
		return false
	end
end

--- Enable the config mode at the currently working connection with the vtsyh console
-- @class function
-- @name enable_config_mode
-- @return	Boolean whether operation succeeded
function quagga.enable_config_mode()
	if quagga.connection then
		if quagga.command('configure terminal') then 
			return true
		else
			return false
		end
	else
		return false
	end
end

--- Save the currently changes at the configuration file
-- @class function
-- @name write_file
-- @return	Boolean whether operation succeeded
function quagga.write_file()
	if quagga.connection then
		if quagga.command('write file') then 
			return true
		else
			return false
		end
	else
		return false
	end
end

--- Set the hostname of the working node
-- @class function
-- @name set_hostname
-- @param name Hostname of the working node
-- @return	Boolean whether operation succeeded
function quagga.set_hostname(name)
	if quagga.connection then
		if quagga.command('hostname ' .. name) then 
			return true
		else
			return false
		end
	else
		return false
	end
end

--- Set the AS of the working node
-- @class function
-- @name set_bgp_as
-- @param as AS of the working node 
-- @return	Boolean whether operation succeeded
function quagga.set_bgp_as(as)
	if quagga.connection then
		if quagga.command('router bgp ' .. as) then
			return true
		else
			return false
		end
	else
		return false
	end
	
end

--- Add a neighbor 
-- @class function
-- @name add_neighbor
-- @param ip IP of the neighbor
-- @param as AS of the neighbor
-- @return	Boolean whether operation succeeded
function quagga.add_neighbor(ip, as)
	if quagga.connection then
		if quagga.command('neighbor ' .. ip ' remote-as '.. as) then
			return true
		else
			return false
		end
	else
		return false
	end
end

--- Add a network to publish
-- @class function
-- @name add_network
-- @param network Network range to be added
-- @return	Boolean whether operation succeeded
function quagga.add_network(network)
	if quagga.connection then
		if quagga.command('network ' .. network) then
			return true
		else
			return false
		end
	else
		return false
	end
end

--- Remove a neighbor 
-- @class function
-- @name remove_neighbor
-- @param ip IP of the neighbor
-- @param as AS of the neighbor
-- @return	Boolean whether operation succeeded
function quagga.remove_neighbor(ip, as)
	if quagga.connection then
		if quagga.command('no neighbor ' .. ip ' remote-as '.. as) then
			return true
		else
			return false
		end
	else
		return false
	end
end

--- Remove a published network from the configuration file
-- @class function
-- @name remove_network
-- @param network Network range to be removed
-- @return	Boolean whether operation succeeded
function quagga.remove_network(network)
	if quagga.connection then
		if quagga.command('no network ' .. network) then
			return true
		else
			return false
		end
	else
		return false
	end
end

--- Add a interfacedevice to the currently working routing mode
-- @class function
-- @name add_interface
-- @param interface Interfice to add at the configuration file
-- @return	Boolean whether operation succeeded
function quagga.add_interface(interface)
	if quagga.connection then
		if quagga.command('interface ' .. interface) then
			return true
		else
			return false
		end
	else
		return false
	end
end

--- Remove a interfacedevice to the currently working routing mode
-- @class function
-- @name remove_interface
-- @param interface Interfice to remove from the configuration file
-- @return	Boolean whether operation succeeded
function quagga.remove_interface(interface)
	if quagga.connection then
		if quagga.command('no interface ' .. interface) then
			return true
		else
			return false
		end
	else
		return false
	end
end

--- Set id of the working node
-- @class function
-- @name set_router_id
-- @param id ID of the working node. Should be it's IP address
-- @return	Boolean whether operation succeeded
function quagga.set_router_id(id)
	if quagga.connection then
		if quagga.command('bgp router-id ' .. id) then
			return true
		else
			return false
		end
	else
		return false
	end
end

return quagga

