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

luciutil = require "luci.util"
util = {}
util.luci = luciutil

-- Replace p1 for p2, p1 might be an array
function util.replace(s,p1,p2)
	if s == nil then
		return nil
	end
	local sout
	if type(p1) == "table" then
		local i,p
		sout = s
		for i,p in ipairs(p1) do
			sout = string.gsub(sout,p,p2)
		end
	else
		sout = string.gsub(s,p1,p2)
	end

	return sout
end

function util.find(s,p)
	return string.find(s,p)
end

function util.printf(...)
	local s,c = pcall(string.format,...)
	if not s then c = "" end
	return c
end

return util
