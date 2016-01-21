#!/usr/bin/lua

local OPENWRT_CONFIG_SYSTEM_FILENAME = "system"
local KERNEL_HOSTNAME = "/proc/sys/kernel/hostname"

local io = require("io")
local ubus = require("ubus")
local uci = require("uci")

local qmp_defaults = require("qmp_defaults")
local qmp_uci = require("qmp_uci")

local qmp_system = {}

-- Get the device hostname
local function get_hostname()

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

-- Set the device hostname
local function set_hostname(hostname)

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



qmp_system.get_hostname = get_hostname
qmp_system.set_hostname = set_hostname

return qmp_system