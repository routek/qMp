#!/usr/bin/lua

local OWRT_CONFIG_DIR = "/etc/config/"
local QMP_CONFIG_FILENAME = "qmp"

local qmp_defaults = require("qmp_defaults")
local qmp_io = require("qmp_io")
local qmp_uci = require("qmp_uci")

local qmp_config = {}

local initialize



-- Initialize the qMp configuration file with the default sections and paramenters
function initialize()

  -- Check if the configuration file exists or create it
  if qmp_io.is_file(OWRT_CONFIG_DIR .. QMP_CONFIG_FILENAME) or qmp_io.new_file(OWRT_CONFIG_DIR .. QMP_CONFIG_FILENAME) then

    -- Create the node section or, if already present, add any missing value
    qmp_uci.new_section_typename(QMP_CONFIG_FILENAME, "qmp", "node")
    local ndefaults = qmp_defaults.get_node_defaults()

    -- In the past, community_id and community_node_id options were [oddly] used.
    -- If upgrading a device, take it into account
    local community_node_id = qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "node", "community_node_id")
    if community_node_id then
      qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "node", "community_node_id", '')
      local node_id = qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "node", "community_id")
      qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "node", "node_id", node_id)
      qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "node", "community_id", '')
    end

    -- Remove parameters from previous versions which no longer must be here
    qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "node", "primary_device", '')
    qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "node", "key", '')

    -- Merge the missing values from the defaults
    for k, v in pairs(ndefaults) do
      if not qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "node", k) then
        qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "node", k, v)
      end
    end


  end
end



qmp_config.initialize = initialize

return qmp_config

