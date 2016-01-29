--[[
    Copyright (C) 2016 Fundacio Privada per a la Xarxa Oberta, Lliure i Neutral guifi.net

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

        Roger Pueyo Centelles <qmp@rogerpueyo.com>
--]]

module("luci.controller.qmp.config", package.seeall)

function index()

	entry({"qmp","configuration"}, call("dummy"), "Configuration", 20).dependent=false
	entry({"qmp", "configuration", "system"}, cbi("qmp/system"), "System settings", 10).dependent=false
  entry({"qmp", "configuration", "network"}, cbi("qmp/network"), "Network settings", 10).dependent=false
	entry({"qmp","configuration","dummy"}, call("dummy_ubus"), "Dummy Ubus function", 20).dependent=false

end

function dummy_ubus()
 local ubus = require "ubus"
 local conn = ubus.connect()
 local result = conn:call("system", "board", {})
 luci.http.prepare_content("application/json")
 luci.http.write_json(result)
end

