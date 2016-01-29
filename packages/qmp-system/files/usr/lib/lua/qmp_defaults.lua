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

-- Default hostname
local hostname = "qMp"


-- Wireless section

-- Default wifi-iface adhoc BSSID for Ad-Hoc wireless mode
local wi_adhoc_bssid = "02:CA:FF:EE:BA:BE"


-- Default wifi-device country regulatory domain
local wd_country = "US"
-- Default wifi-device multicast rate (mcast_rate), in kb/s, for
local wd_mcast_rate = 18000
-- Default wifi-device noscan
local wd_noscan = 1
-- Default wifi-device type
local wd_type = "mac80211"


local function get_default_hostname()
  return node_id
end



local function get_wifi_iface_adhoc_defaults()
  local t = {}
  t["bssid"] = bssid
  return (t)
end


local function get_wifi_device_defaults()
  local t = {}
  t["country"] = wd_country
  t["mcast_rate"] = wd_mcast_rate
  t["noscan"] = wd_noscan
  t["type"] = wd_type
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
qmp_defaults.get_wifi_device_defaults = get_wifi_device_defaults
qmp_defaults.get_wifi_iface_adhoc_defaults = get_wifi_iface_adhoc_defaults

return qmp_defaults