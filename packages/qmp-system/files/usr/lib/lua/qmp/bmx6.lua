#!/usr/bin/lua

local BMX6_BIN_FILENAME = "/usr/sbin/bmx6"
local BMX6_CONFIG_FILENAME = "bmx6"
local QMP_CONFIG_FILENAME = "qmp"

local luci_sys     = require("luci.sys")

local qmp_uci      = qmp_uci      or require("qmp.uci")
local qmp_defaults = qmp_defaults or require("qmp.defaults")
local qmp_io       = qmp_io       or require("qmp.io")
local qmp_ipv4     = qmp_ipv4     or require("qmp.ipv4")
local qmp_network  = qmp_network  or require("qmp.network")
local qmp_tools    = qmp_tools    or require("qmp.tools")
local qmp_wireless = qmp_wireless or require("qmp.wireless")


local qmp_bmx6 = qmp_bmx6 or {}

-- Set the main Get the list of switch devices (e.g. switch0, switch1)
local function configure_tmain()

  -- Create the tunDev-typed tmain section if not already there
  qmp_uci.new_section_typename(BMX6_CONFIG_FILENAME, "tunDev", "tmain")

  -- Set the tmain IPv4 address

  local mesh_ipv4_address = qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "ip", "mesh_ipv4_address")
  local mesh_ipv4_netmask = qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "ip", "mesh_ipv4_netmask")
  local tun4address = mesh_ipv4_address .. '/' .. qmp_ipv4.netmask_full_to_cidr(mesh_ipv4_netmask)
  qmp_uci.set_option_typenamesec(BMX6_CONFIG_FILENAME, "tunDev", "tmain", "tun4Address", tun4address)

end


-- Initialize BMX6 configuration file
local function initialize()

  -- Configure the tmain tunnel
  configure_tmain()

end

qmp_bmx6.configure_tmain = configure_tmain
qmp_bmx6.initialize = initialize


return qmp_bmx6
