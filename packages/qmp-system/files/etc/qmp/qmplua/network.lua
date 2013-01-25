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
--! @brief networking functions

model = require "qmp.model"
model.set_file('network')

network = {}

--! @brief Add a interface [by default proto = none]
--! @param as AS of the BGP peer
--! @param name	UCI section name
--! @param iface interface
function network.add_if(name, iface)
	model.set_file('wireless')
	model.add_type('wifi-iface', {'network' = name})

	model.set_file('network')
	model.add('interface', name)
	model.set(name, 'proto', 'none')
	model.set(name, 'ifname', iface)
	model.apply()
end

--! @brief Add a bridge [by default proto = none]
--! @param name	UCI section name
--! @param ifaces (string) With the interfaces of the breach 
function network.add_br(name, ifaces)
	model.add('interface', name)
	model.set(name, 'proto', 'none')
	model.set(name, 'ifname', ifaces)
	model.set(name, 'type', 'bridge')
	model.apply()
end

--! @brief Add an virtual interface [by default proto = none]
--! @param name	UCI section name
--! @param iface interface
--! @param tag tag for the virutal interface
function network.add_alias(name, iface, tag)
	model.add('interface', name)
	ifname = '@' .. iface .. '.' .. tag
	model.set('ifname', ifname)
	model.set(name, 'proto', 'none')
	model.apply()
end

--! @brief Set a IPv4 to a interface [by default proto = static]
--! @param name	UCI section name
--! @param ip 	IP for the interface 
--! @param netmask Netmask for the interface 
function network.set_ipv4(name, ip, mask)
	model.delete(name, 'ip6addr')
	model.set(name, 'ipaddr', ip)
	model.set(name, 'netmask', mask)
	model.set(name, 'proto', 'static')
	model.apply()
end

--! @brief Deletes a IPv4 from a interface
function network.delete_ipv4(name)
	model.delete(name, 'ipaddr')
	model.delete(name, 'netmask')
	model.apply()
end

--! @brief Deletes a IPv6 from a interface
function network.delete_ipv6(name)
	model.delete(name, 'ip6addr')
	model.apply()
end

--! @brief Set a IPv6 to a interface [by default proto = static]
--! @param name	UCI section name
--! @param network 	Network for the interface 
function network.set_ipv6(name, network)
	model.delete(name, 'ipaddr')
	model.delete(name, 'netmask')
	model.set(name, 'ip6addr', network)
	model.set(name, 'proto', 'static')
	model.apply()
end

--! @brief Set a interface as dhcp [by default proto = dhcp]
--! @param name	UCI section name
function network.set_dhcp(name)
	model.set(name, 'proto', 'dhcp')
	model.apply()
end

--! @brief Restart the network daemon
function network.restart_daemon()
	os.execute('/etc/init.d/network restart')
end

return network
