#!/usr/bin/lua

local PATH_SYS_CLAS_80211 = "/sys/class/ieee80211/"

local QMP_CONFIG_FILENAME = "qmp"

local qmp_uci = require("qmp_uci")
local qmp_defaults = require("qmp_defaults")
local qmp_network = require("qmp_network")
local qmp_io = require("qmp_io")

local qmp_wireless = {}

-- Initialize the wireless interfaces configuration
local function initial_setup()

  -- Create the wireless section of type qmp in qmp's config file, if it does not exist
  qmp_uci.new_section_typename(QMP_CONFIG_FILENAME, "qmp", "wireless")

  -- Get the wireless default values
  local t = qmp_defaults.get_wireless_defaults()

  -- Set the missing default values
  for k, v in pairs(t) do
    if not qmp_uci.isset_option_secname(QMP_CONFIG_FILENAME, "wireless", k) then
      qmp_uci.set_option(QMP_CONFIG_FILENAME, "wireless", k, v)
    end
  end


end



-- Get an array with the wireless (IEEE 802.11) physical devices (e.g. phy0, phy1, phy2)
local function get_wireless_phy_devices()

  return qmp_io.ls(PATH_SYS_CLAS_80211)

end



-- Get an array with the wireless (IEEE 802.11) radio devices (e.g. radio0, radio1, radio2)
local function get_wireless_radio_devices()

  local rdevices = {}

	local conn = ubus.connect()
	if conn then
		local status = conn:call("network.wireless", "status", {})

    -- Check all the devices returned by the Ubus call
		for k, v in pairs(status) do
      table.insert(rdevices, k)
    end

		conn:close()
	end

  return rdevices

end



qmp_wireless.initial_setup = initial_setup
qmp_wireless.get_wireless_radio_devices = get_wireless_radio_devices
qmp_wireless.get_wireless_phy_devices = get_wireless_phy_devices

return qmp_wireless