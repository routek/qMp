#!/usr/bin/lua

local qmp_defaults = {}

-- Default BSSID for Ad-Hoc wireless mode
local bssid = "02:CA:FF:EE:BA:BE"
-- Default multicast rate (mcast_rate), in kb/s, for
local mcast_rate = 18000
-- Default country regulatory domain
local country = "US"


local function get_wireless_defaults()
  local t = {}
  t["bssid"] = bssid
  t["mcast_rate"] = mcast_rate
  t["country"] = country
  return (t)
end

qmp_defaults.get_wireless_defaults = get_wireless_defaults

return qmp_defaults