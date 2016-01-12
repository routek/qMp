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

module("luci.controller.qmp.index", package.seeall)

function index()

  -- Make qMp interface the default one, instead of OpenWrt's
  local root = node()
  root.target = alias("qmp")
  root.index = true

  local page   = node("qmp")
  page.target  = firstchild()
  page.title   = _("Quick Mesh Project")
  page.order   = 1
  page.sysauth = "root"
  page.sysauth_authenticator = "htmlauth"
  page.ucidata = true
  page.index = true

  -- Add status page, using OpenWrt's template
  entry({"qmp","status"}, template("admin_status/index"), "Status", 10).dependent=false

  -- Empty tools menu to be populated by addons and other packages
  entry({"qmp", "services"}, firstchild(), _("Tools"), 50).index = true

  -- Logout button
  entry({"qmp", "logout"}, call("action_logout"), _("Logout"), 90)
end

function action_logout()
  local dsp = require "luci.dispatcher"
  local utl = require "luci.util"
  local sid = dsp.context.authsession

  if sid then
    utl.ubus("session", "destroy", { ubus_rpc_session = sid })

    dsp.context.urltoken.stok = nil

    luci.http.header("Set-Cookie", "sysauth=%s; expires=%s; path=%s/" %{
            sid, 'Thu, 01 Jan 1970 01:00:00 GMT', dsp.build_url()
    })
  end

  luci.http.redirect(luci.dispatcher.build_url())
end


