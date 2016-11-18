#!/usr/bin/lua

local KERNEL_HOSTNAME = "/proc/sys/kernel/hostname"
local OPENWRT_CONFIG_SYSTEM_FILENAME = "system"
local QMP_CONFIG_FILENAME = "qmp"

local io = require("io")
local ubus = require("ubus")
local uci = require("uci")

local qmp_system = qmp_system or {}

local qmp_io     = qmp_io    or require("qmp.io")
local qmp_uci    = qmp_uci   or require("qmp.uci")
local qmp_tools  = qmp_tools or require("qmp.tools")


-- Local functions declaration
local configure_hostname
local get_community_id
local get_hostname
local generate_key
local get_key
local get_node_id
local get_primary_device
local set_hostname


-- Configure the device hostname
--
-- The device hostname consists of three concatenated items:
--  - The Community Network ID [optional] (e.g. GS for GuifiSants, P9SF for Poble Nou Sense Fils)
--  - The node hostname
--  - The last four digits of the primary network device's MAC address, lowercase (e.g. E4:5F => e45f)
function configure_hostname()

  local hostname = ""

  -- Add the community_id field (if present) and a hyphen
  local community_id = get_community_id()
  if type(community_id) == "string" then
    hostname = hostname .. community_id
  end
  if string.len(hostname) > 0 then
    hostname = hostname .. "-"
  end

  -- Add the node_id field
  hostname = hostname .. get_node_id() .. "-"

  -- Add the MAC digits
  local mac = qmp_network.get_device_mac(get_primary_device())
  if qmp_network.is_valid_mac(mac) then
    hostname = hostname .. string.sub(mac,13,14) .. string.sub(mac,16,17)
  else
    hostname = hostname .. "0000"
  end

  -- Update the system
  set_hostname (hostname)

  return
end



-- Get the device community_id
function get_community_id()
	return qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "node", "community_id")
end



-- Get the device hostname
function get_hostname()

	local hostname = nil

  -- First try retrieving it from Ubus
	local conn = ubus.connect()
	if conn then
		local status = conn:call("system", "board", {})
		for k, v in pairs(status) do
			if k == "hostname" then
				hostname = v
			end
		end
		conn:close()
		return hostname
	end

  -- Try UCI otherwise
	local cursor = uci.cursor()
	cursor:foreach("system", "system", function(s)
			hostname = cursor:get("system", s[".name"], "hostname")
			if hostname ~= nil then
				return
			end
		end)
	return hostname

end

-- Generate the device mesh key
function generate_key()
  -- Get the primary device's MAC address last digits to feed it to the random seed
  mac = qmp_network.get_device_mac(qmp_network.get_primary_device()):gsub('%W','')
  macseed = tonumber(string.sub(mac,-4,-1),16)

  return qmp_tools.get_random_hex(32,macseed)
end

-- Get the device mesh key
function get_key()
  key = qmp_io.read_file(qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "node", "key"))
  if key ~= nil then
    return key[1]
  end
end

-- Get the device node_id
function get_node_id()
	return qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "node", "node_id")
end


-- Get the primary network device in qmp config file
function get_primary_device()
	return qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "devices", "primary_device")
end


-- Set the device hostname
function set_hostname(hostname)

  -- Check for appropriate type and length
	if type(hostname) == "string" then
	  if string.len(hostname) > 0 and string.len(hostname) < 254 then

      -- Check for valid characters (a-Z, 0-9, dot, hyphen and underscore)
      if hostname == string.match(hostname,'[a-zA-Z0-9_.-]*') then

        -- Check that there are no leading nor trailing dots, hyphens or underscores
        if string.sub(hostname,1,1) == string.match(string.sub(hostname,1,1),'[a-zA-Z0-9]*') and string.sub(hostname,-1,-1) == string.match(string.sub(hostname,-1,-1),'[a-zA-Z0-9]*') then

          -- Update system config
          qmp_uci.set_option_nonamesec(OPENWRT_CONFIG_SYSTEM_FILENAME, "system", 0, "hostname", hostname)

          -- Update kernel
          local file = io.open(KERNEL_HOSTNAME, "w+")
          if file then
            file:write(hostname)
            file:close()
          end
        end
	    end
	  end
	end

	return

end



qmp_system.configure_hostname = configure_hostname
qmp_system.get_hostname = get_hostname
qmp_system.generate_key = generate_key
qmp_system.get_key = get_key
qmp_system.get_node_id = get_node_id
qmp_system.get_community_id = get_community_id
qmp_system.get_primary_device = get_primary_device
qmp_system.set_hostname = set_hostname

return qmp_system
