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
--! @brief log and debug functions

debug = {}
local namespace = "Main"
local stdout = "-s"
local priority = "-p 7"

function debug.set_namespace(t)
	if t ~= nil then
		namespace = t
	end
end

function debug.set_priotiry(n)
	if n then
		priority = "-p "..n
	else
		priotiry = ""
	end
end

function debug.set_stdout(b)
	if b then
		stdout = "-s"
	else
		stdout = ""
	end
end

--! @brief Add one line to the system log file with the tag qMp
--! @param msg string with the error message
--! return exit status of the logger call
function debug.logger(msg)
	local logger = string.format("logger %s %s -t qMp[%s] '",stdout,priority,namespace)
	local status, c = pcall(os.execute,logger .. msg .. "'")
	return status		
end

return debug
