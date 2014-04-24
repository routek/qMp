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

uci = require "luci.model.uci"

qmp_model = {}

function qmp_model.get(section, option)
	local c = uci.cursor()
	if section and option then
		return c:get('qmp', section, option)
	else
		return false
	end
end

function qmp_model.add(section, option, value)
	return qmp_model.set(section, option, value)
end

function qmp_model.del(section, option)
	local c = uci.cursor()
	return c:delete('qmp', section, option)
end

function qmp_model.set(section, option, value)
	local c = uci.cursor()
	if section and option then
		return c:set('qmp', section, option, value)
	else
		return false
	end
end

function qmp_model.get_type(type, index, option)
	local c = uci.cursor()
	if index then
		if option then
			return qmp_model.get_type_option(type, index, option)
		else
			return qmp_model.get_type_index(type, index)
		end
	else
		return qmp_model.get_all_type(type)
	end
end

function qmp_model.get_all_type(type)
	local c = uci.cursor()
	local gt = {}
	if c:foreach('qmp', type, function (t) table.insert(gt, t) end) then
		return gt
	else
		return false
	end
end

function qmp_model.get_indexes(type, index)
	local c = uci.cursor()
	local gt = {}
	if c:foreach('qmp', type, function (t) if t['.index'] == index then table.insert(gt, t) end end) then
		return gt
	else
		return false
	end
end

function qmp_model.get_type_option(type, index, option)
	local c = uci.cursor()
	local gt = {}
	if c:foreach('qmp', type, function (t) if t['.index'] == index then table.insert(gt, t) end end) then
		return gt[option]
	else
		return false
	end
end

function qmp_model.set_type(type, index, option)
	local c = uci.cursor()

end

function qmp_model.raw()
	return uci.cursor()
end
