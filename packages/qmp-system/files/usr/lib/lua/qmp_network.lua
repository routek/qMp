#!/usr/bin/lua

local PATH_SYS_VIRTUAL_NET = "/sys/devices/virtual/net/"
local PATH_SYS_CLASS_NET = "/sys/devices/virtual/net/"

local ubus = require "ubus"
local uci = require("uci")

local qmp_uci = require("qmp_uci")
local qmp_defaults = require("qmp_defaults")

local qmp_network = {}

-- Get an array with the physical raw Ethernet devices (e.g. eth0, eth1, eth2),
-- excluding wireless and the virtual ones like "lo" (localhost), VLANs, etc.
local function get_ethernet_devices()

  local devices = {}

	local conn = ubus.connect()
	if conn then
		local status = conn:call("network.device", "status", {})

    -- Check all the devices returned by the Ubus call
		for k, v in pairs(status) do

      -- Check for devices with "Network device" in the "type" field
			for l, w in pairs(v) do
  			if l == "type" and w == "Network device" then

  			  -- Check for virtual devices to discard them
  			  local f = io.open(PATH_SYS_VIRTUAL_NET .. k)
  			  if f then
  			    f:close()
  			  else
            table.insert(devices, k)
          end
  			end
			end
		end
		conn:close()
	end

  return devices

end



qmp_network.get_ethernet_devices = get_ethernet_devices

return qmp_network