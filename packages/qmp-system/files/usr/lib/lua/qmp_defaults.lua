#!/usr/bin/lua

local qmp_defaults = {}

-- Node section
-- Default device (node) name
local node_id = "qMp"
-- Default community id (none)
local community_id = ''
-- Default latitude
local latitude = '0.0'
-- Default longitude
local longitude = '0.0'
-- Default elevation
local elevation = '5.0'
-- Default contact
local contact = 'your@email.qmp'

-- Wireless section
-- Default BSSID for Ad-Hoc wireless mode
local bssid = "02:CA:FF:EE:BA:BE"
-- Default country regulatory domain
local country = "US"
-- Default hostname
local hostname = "qMp"
-- Default multicast rate (mcast_rate), in kb/s, for
local mcast_rate = 18000
       


local function get_default_hostname()
  return node_id
end



local function get_wireless_defaults()
  local t = {}
  t["bssid"] = bssid
  t["mcast_rate"] = mcast_rate
  t["country"] = country
  return (t)
end



local function get_node_defaults()
  local t = {}
  t["node_id"] = node_id
  t["community_id"] = community_id
  t["latitude"] = latitude
  t["longitude"] = longitude
  t["elevation"] = elevation
  t["contact"] =  contact
  return (t)
end

qmp_defaults.get_default_hostname = get_default_hostname
qmp_defaults.get_node_defaults = get_node_defaults
qmp_defaults.get_wireless_defaults = get_wireless_defaults

return qmp_defaults