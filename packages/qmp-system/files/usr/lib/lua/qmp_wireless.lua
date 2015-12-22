#!/usr/bin/lua

local QMP_CONFIG_FILENAME = "qmp"

local qmp_uci = require("qmp_uci")
local qmp_defaults = require("qmp_defaults")

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


qmp_wireless.initial_setup = initial_setup

return qmp_wireless