--[[
    Copyright (C) 2013 Quick Mesh Project
    Contributors:
       Jorge L. Florit

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

module("luci.controller.guifi", package.seeall)

function index()
	-- setting place from pre-defined value
	local place = {"qmp","Guifi"}

	-- setting position of menu
	local position = "6"

	-- Guifi oneclick menu entry
	entry(place,call("action_guifi"),place[#place],tonumber(position))
	table.remove(place)
end
					
function action_guifi()
	package.path = package.path .. ";/etc/qmp/?.lua"
	local qmp = require "qmpinfo"
	local key = qmp.get_key()
	luci.template.render("qmp/guifi",{key=key})
end
