#!/usr/bin/lua

local ubus = require "ubus"
local uci = require("uci")


local qmp_system = {}

-- Get the device name. First try retrieving it from Ubus, otherwise use UCI
local function get_hostname()

	local hostname = nil

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

	local cursor = uci.cursor()
	cursor:foreach("system", "system", function(s)
			hostname = cursor:get("system", s[".name"], "hostname")
			if hostname ~= nil then
				return
			end
		end)
	return hostname

end


qmp_system.get_hostname = get_hostname

return qmp_system