#!/usr/bin/lua

local PATH_SYS_VIRTUAL_NET = "/sys/devices/virtual/net/"
local PATH_SYS_CLASS_NET = "/sys/class/net/"

local ubus = require "ubus"
local uci = require("uci")

local qmp_uci = require("qmp_uci")
local qmp_defaults = require("qmp_defaults")

local qmp_network = {}


-- Get all the network devices, (e.g. lo, eth0, eth1.12, br-lan, tunn33, wlan0ap)
local function get_all_devices()

  local devices = {}

	local conn = ubus.connect()
	if conn then
		local status = conn:call("network.device", "status", {})

    -- Check all the devices returned by the Ubus call
		for k, v in pairs(status) do
		  -- table.insert(devices, k)
		print (k)
		end
		conn:close()
	end

  return devices

end

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

            -- Check for IEEE 802.11 wireless devices to discard them
            local f = io.open(PATH_SYS_CLASS_NET .. k .. "/phy80211")

            if then
              f:close()
            else
              -- The interface is not VLAN, localhost, wireless, etc.
              table.insert(devices, k)
            end
          end
  			end
			end
		end
		conn:close()
	end

  return devices

end



qmp_network.get_ethernet_devices = get_ethernet_devices
qmp_network.get_all_devices = get_all_devices

return qmp_network