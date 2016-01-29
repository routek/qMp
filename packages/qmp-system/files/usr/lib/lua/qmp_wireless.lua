#!/usr/bin/lua

local PATH_SYS_CLAS_80211 = "/sys/class/ieee80211/"

local QMP_CONFIG_FILENAME = "qmp"

local luci_sys     = require("luci.sys")


local qmp_uci      = qmp_uci      or require("qmp_uci")
local qmp_defaults = qmp_defaults or require("qmp_defaults")
local qmp_io       = qmp_io       or require("qmp_io")
local qmp_network  = qmp_network  or require("qmp_network")
local qmp_tools    = qmp_tools    or require("qmp_tools")


local qmp_wireless = qmp_wireless or {}

local get_device_mac
local get_radio_iwinfo
local get_radio_phy
local get_radios_band
local get_radios_band_2g
local get_radios_band_5g
local get_radios_band_dual
local get_wireless_phy_devices
local get_wireless_radio_devices
local initial_setup
local is_phy_device
local is_radio_device
local is_radio_band
local is_radio_band_2g
local is_radio_band_5g
local is_radio_band_dual



-- Get the MAC address (lowercase) of a wireless device
local function get_device_mac(wdev)

  -- Check if the device is a radio wireless device and get its phy
  if is_radio_device(wdev) then
    wdev = get_radio_phy(wdev)
  end

  -- Check if the device is a phy wireless device
  if is_phy_device(wdev) then
    local f = io.open(PATH_SYS_CLAS_80211 .. wdev .. "/macaddress")
    if f then
      -- read the MAC address (17 characters: 12 MAC + 5 colons)
      local mac = f:read(17)
      f:close()
      if qmp_network.is_valid_mac(mac) then
        return string.lower(mac)
      end
    end
  end

  return nil
end


-- Initialize the wireless interfaces configuration [DEPRECATED]
function initial_setup()

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


-- Get the device iwinfo object instance of a radio device
function get_radio_iwinfo(radiodev)

    if is_radio_device(radiodev) then
    return luci_sys.wifi.getiwinfo(radiodev)
  end

  return nil
end


-- Get the corresponding phy device of a radio device
function get_radio_phy(radiodev)

  if is_radio_device(radiodev) then
    local number = string.match(radiodev, "%d+")
    return ("phy" .. number)
  end

  return nil
end


-- Get an array with the radios capable of the given band
function get_radios_band(band)

  if band == "2g" then
    return get_radios_band_2g()
  elseif band == "5g" then
    return get_radios_band_5g()
  elseif band == "dual" then
    return get_radios_band_dual()
  end

  return {}
end


-- Get an array with the 2.4 GHz capable radios
function get_radios_band_2g()

  local radios = {}

  for k,v in pairs(get_wireless_radio_devices()) do
    if is_radio_band_2g(v) then
      table.insert(radios, v)
    end
  end

  return radios
end


-- Get an array with the 5 GHz capable radios
function get_radios_band_5g()

  local radios = {}

  for k,v in pairs(get_wireless_radio_devices()) do
    if is_radio_band_5g(v) then
      table.insert(radios, v)
    end
  end
  return radios
end


-- Get an array with the dual-band capable radios
function get_radios_band_dual()

  local radios = {}

  for k,v in pairs(get_wireless_radio_devices()) do
    if is_radio_band_dual(v) then
      table.insert(radios, v)
    end
  end

  return radios
end


-- Check if the device is a phy device
function is_phy_device(device)
  return qmp_tools.is_item_in_array(device, get_wireless_phy_devices())
end


-- Check if a radio device can operate on the given band
function is_radio_band(radiodev, band)

  if is_radio_device(radiodev) then
    if band == "2g" then
      is_radio_band_2g(radiodev)
    elseif band == "5g" then
      return is_radio_band_5g(radiodev)
    elseif band == "dual" then
      return is_radio_band_dual(radiodev)
    end
  end
  return nil
end


-- Check if a radio device can operate on the 2.4 GHz band
function is_radio_band_2g(radiodev)

  if is_radio_device(radiodev) then
    local iw = get_radio_iwinfo(radiodev)
    for k, v in pairs(iw.hwmodelist) do
      if (k == "b" or k == "g") and v == true then
        return true
      end
    end

    return false
  end
  return nil
end


-- Check if a radio device can operate on the 5 GHz band
function is_radio_band_5g(radiodev)

  if is_radio_device(radiodev) then
    local iw = get_radio_iwinfo(radiodev)
    for k, v in pairs(iw.hwmodelist) do
      if (k == "a" or k == "ac") and v == true then
        return true
      end
    end

    return false
  end
  return nil
end


-- Check if a radio device can operate on the 5 GHz band
function is_radio_band_dual(radiodev)

  if is_radio_device(radiodev) then
    if is_radio_band_2g(radiodev) and is_radio_band_5g(radiodev) then
      return true
    else
      return false
    end
  else
    return false
  end

  return nil
end




-- Check if the device is a radio device
function is_radio_device(device)
  return qmp_tools.is_item_in_array(device, get_wireless_radio_devices())
end



-- Get a sorted array with the wireless (IEEE 802.11) physical devices (e.g. phy0, phy1, phy2)
function get_wireless_phy_devices()
  local pdevices = {}

  for k, v in pairs(qmp_io.ls(PATH_SYS_CLAS_80211)) do
    table.insert(pdevices, v)
  end

  table.sort(pdevices)

  return pdevices
end



-- Get a sorted array with the wireless (IEEE 802.11) radio devices (e.g. radio0, radio1, radio2)
function get_wireless_radio_devices()

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

  table.sort(rdevices)
  return rdevices

end



qmp_wireless.get_device_mac = get_device_mac
qmp_wireless.get_radio_iwinfo = get_radio_iwinfo
qmp_wireless.get_radio_phy = get_radio_phy
qmp_wireless.get_radios_band = get_radios_band
qmp_wireless.get_radios_band_2g = get_radios_band_2g
qmp_wireless.get_radios_band_5g = get_radios_band_5g
qmp_wireless.get_radios_band_dual = get_radios_band_dual
qmp_wireless.get_wireless_radio_devices = get_wireless_radio_devices
qmp_wireless.get_wireless_phy_devices = get_wireless_phy_devices
qmp_wireless.initial_setup = initial_setup
qmp_wireless.is_phy_device = is_phy_device
qmp_wireless.is_radio_device = is_radio_device
qmp_wireless.is_radio_band = is_radio_band
qmp_wireless.is_radio_band_2g = is_radio_band_2g
qmp_wireless.is_radio_band_5g = is_radio_band_5g
qmp_wireless.is_radio_band_dual = is_radio_band_dual

return qmp_wireless