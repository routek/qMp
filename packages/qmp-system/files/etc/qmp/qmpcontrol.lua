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
    the file called COPYING.
--]]

local qmpcontrol = require "qmp.control"

function print_help(what)

	if what == nil then
		print("qmpcontrol <function> [parameters|help]")
		print(" Functionality list:")
		print(" \t network")
		print(" \t wifi")
		print(" \t bgp")
		print(" \t help")

	elseif what == 'network' then
		print("qmpcontrol network <configure|apply> [parameters]")
		print(" configure parameters:")
		print(" \t devices")
	end
	
	os.exit(1)
end

function network_control()
	if arg[2] == nil then 
		print_help("network")
	elseif arg[2] == "configure" then
		network_configure()
	end
		
end

function network_configure()
	if arg[3] == nil then
		print_help("network")
	elseif arg[3] == "devices" then
		qmpcontrol.configure_net_devices()
	end
end

function bgp_control()
	print("BGP stuff")
end

function wifi_control()
	print("WIFI stuff")
end


if arg[1] == nil then
	print_help()
elseif arg[1]:match("^network") then
	network_control() 
elseif arg[1]:match("^bgp") then
	bgp_control()
elseif arg[1]:match("^wifi") then
	wifi_control()
else
	print_help()
end




