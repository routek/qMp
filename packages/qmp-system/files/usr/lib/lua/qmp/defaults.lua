#!/usr/bin/lua

local qmp_system = qmp_system or require("qmp.system")

local qmp_defaults = qmp_defaults or {}

local get_default_hostname
local get_node_defaults
local get_wifi_iface_defaults
local get_wifi_iface_adhoc_defaults
local get_wifi_iface_ap_defaults
local get_wifi_iface_mesh_defaults
local get_wifi_iface_sta_defaults
local get_wifi_device_defaults


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
-- Default key location
local key = '/tmp/qmp_key'

-- Default hostname
local hostname = "qMp"


-- Wireless defaults

-- Default wifi-device country regulatory domain
local wd_country = "US"
-- Default wifi-device multicast rate (mcast_rate), in kb/s, for
local wd_mcast_rate = 18000
-- Default wifi-device noscan
local wd_noscan = 1
-- Default wifi-device type
local wd_type = "mac80211"


-- Default wifi-iface SSID
local wi_ssid = string.sub(qmp_system.get_hostname(),1,32)

-- Default wifi-iface BSSID for Ad-Hoc wireless mode
local wi_adhoc_bssid = "02:CA:FF:EE:BA:BE"
-- Default wifi-iface SSID for Ad-Hoc wireless mode
local wi_adhoc_ssid = wi_ssid

-- Default wifi-iface encryption for AP mode
local wi_ap_encryption = "none"
-- Default wifi-iface SSID for AP mode
local wi_ap_ssid = wi_ssid

-- Default wifi-iface encryption for AP mode
local wi_ap_encryption = "none"
-- Default wifi-iface SSID for AP mode
local wi_ap_ssid = "qMp"

-- Default wifi-iface mesh_id for mesh (802.11s) mode
local wi_mesh_id = "qMp"
-- Default wifi-iface mesh_fwding for mesh (802.112) mode
local wi_mesh_fwding = 0

-- Default wifi-iface encryption for AP mode
local wi_ap_encryption = "none"
-- Default wifi-iface SSID for AP mode
local wi_ap_ssid = "qMp"


function get_default_hostname()
  return node_id
end


function get_node_defaults()
  local t = {}
  t["node_id"] = node_id
  t["community_id"] = community_id
  t["latitude"] = latitude
  t["longitude"] = longitude
  t["elevation"] = elevation
  t["key"] =  key
  t["contact"] =  contact
  return (t)
end


function get_wifi_iface_defaults(phymode)

  local defaults = {}

  if phymode == "adhoc" then
    return (get_wifi_iface_adhoc_defaults())
  end
  if phymode == "ap" then
    return (get_wifi_iface_ap_defaults())
  end
  if phymode == "mesh" then
    return (get_wifi_iface_mesh_defaults())
  end
  if phymode == "sta" then
    return (get_wifi_iface_sta_defaults())
  end

  return (defaults)
end

function get_wifi_iface_adhoc_defaults()
  local defaults = {}
  defaults["bssid"] = wi_adhoc_bssid
  defaults["ssid"] = wi_adhoc_ssid
  return (defaults)
end

function get_wifi_iface_ap_defaults()
  local defaults = {}
  defaults["encryption"] = wi_ap_encryption
  defaults["ssid"] = wi_ap_ssid
  return (defaults)
end

function get_wifi_iface_mesh_defaults()
  local defaults = {}
  defaults["mesh_id"] = wi_mesh_id
  defaults["mesh_fwding"] = wi_mesh_fwding
  return (defaults)
end

function get_wifi_iface_sta_defaults()
  local defaults = {}
  defaults["encryption"] = wi_sta_encryption
  defaults["ssid"] = wi_sta_ssid
  return (defaults)
end


function get_wifi_device_defaults()
  local t = {}
  t["country"] = wd_country
  t["mcast_rate"] = wd_mcast_rate
  t["noscan"] = wd_noscan
  t["type"] = wd_type
  return (t)
end





qmp_defaults.get_default_hostname = get_default_hostname
qmp_defaults.get_node_defaults = get_node_defaults
qmp_defaults.get_wifi_device_defaults = get_wifi_device_defaults
qmp_defaults.get_wifi_iface_defaults = get_wifi_iface_defaults
qmp_defaults.get_wifi_iface_adhoc_defaults = get_wifi_iface_adhoc_defaults
qmp_defaults.get_wifi_iface_ap_defaults = get_wifi_iface_ap_defaults
qmp_defaults.get_wifi_iface_mesh_defaults = get_wifi_iface_mesh_defaults
qmp_defaults.get_wifi_iface_sta_defaults = get_wifi_iface_sta_defaults

return qmp_defaults
