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

local sys = require("luci.sys")

m = Map("bmx6", "bmx6")

local hna = m:section(TypedSection,"hna","HNA")
hna.addremove = true
hna.anonymous = false
local hna_option = hna:option(Value,"hna", "Host Network Announcement")

function hna_option:validate(value)
	local err = sys.call('bmx6 -c --test -a ' .. value)
	if err ~= 0 then
		return nil
	end	
	return value 
end

return m

