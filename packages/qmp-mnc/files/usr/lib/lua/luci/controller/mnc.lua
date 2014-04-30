--[[
    Copyright (C) 2014 Routek S.L.

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

    Contributors:
     Roger Pueyo Centelles <rogerpueyo@routek.net>
--]]

module("luci.controller.mnc", package.seeall)

function index()
	-- setting place from pre-defined value
	local place = {"qmp","MNC"}

	-- setting position of menu
	local position = "5"

	-- MNC menu entry
	entry(place,call("action_mnc"),place[#place],tonumber(position))
	table.remove(place)
end

function action_mnc()
	luci.template.render("qmp/mnc")
end
