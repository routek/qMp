#!/usr/bin/lua

local QMP_CONFIG_FILENAME = "qmp"

local luci_sys     = require("luci.sys")

local qmp_uci      = qmp_uci      or require("qmp.uci")
local qmp_defaults = qmp_defaults or require("qmp.defaults")
local qmp_io       = qmp_io       or require("qmp.io")
local qmp_network  = qmp_network  or require("qmp.network")
local qmp_tools    = qmp_tools    or require("qmp.tools")
local qmp_wireless = qmp_wireless or require("qmp.wireless")


local qmp_ipv4 = qmp_ipv4 or {}

function get_all_netmasks()

  local netmasks = {
    [0]  = "0.0.0.0",
  	[1]  = "128.0.0.0",
  	[2]  = "192.0.0.0",
  	[3]  = "224.0.0.0",
  	[4]  = "240.0.0.0",
  	[5]  = "248.0.0.0",
  	[6]  = "252.0.0.0",
    [7]  = "254.0.0.0",
    [8]  = "255.0.0.0",
  	[9]  = "255.128.0.0",
  	[10] = "255.192.0.0",
  	[11] = "255.224.0.0",
  	[12] = "255.240.0.0",
  	[13] = "255.248.0.0",
  	[14] = "255.252.0.0",
    [15] = "255.254.0.0",
  	[16] = "255.255.0.0",
  	[17] = "255.255.128.0",
  	[18] = "255.255.192.0",
  	[19] = "255.255.224.0",
  	[20] = "255.255.240.0",
  	[21] = "255.255.248.0",
  	[22] = "255.255.252.0",
    [23] = "255.255.254.0",
  	[24] = "255.255.255.0",
  	[25] = "255.255.255.128",
  	[26] = "255.255.255.192",
  	[27] = "255.255.255.224",
  	[28] = "255.255.255.240",
  	[29] = "255.255.255.248",
  	[30] = "255.255.255.252",
  	[31] = "255.255.255.254",
    [32] = "255.255.255.255"
  }
  
  return netmasks

end


function netmask_cidr_to_full(netmask)

  for cidr, full in pairs(get_all_netmasks()) do
    if tostring(netmask) == tostring(cidr) then
      return full
    end
  end

  return nil
end


function netmask_full_to_cidr(netmask)

  for cidr, full in pairs(get_all_netmasks()) do
    if netmask == full then
      return cidr
    end
  end

  return nil
end


qmp_ipv4.get_all_netmasks = get_all_netmasks
qmp_ipv4.netmask_cidr_to_full = netmask_cidr_to_full
qmp_ipv4.netmask_full_to_cidr = netmask_full_to_cidr


return qmp_ipv4


