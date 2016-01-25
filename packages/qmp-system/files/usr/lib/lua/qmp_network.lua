#!/usr/bin/lua

local PATH_SYS_VIRTUAL_NET = "/sys/devices/virtual/net/"
local PATH_SYS_CLASS_NET = "/sys/class/net/"

local ubus = require ("ubus")
local uci = require("uci")
local io = require("io")

local qmp_defaults = require("qmp_defaults")
local qmp_io = require("qmp_io")
local qmp_uci = require("qmp_uci")

local qmp_network = qmp_network or {}


local is_valid_mac
local is_ethernet_device
local is_network_device
local get_primary_device


-- Call u-bus to get network.device status
local function call_ubus_network_device_status()

  local ubusdata = {}

  local conn = ubus.connect()
  if conn then
    ubusdata = conn:call("network.device", "status", {})
    conn:close()
  end

  return ubusdata
end



-- Get all the network devices, (e.g. lo, eth0, eth1.12, br-lan, tunn33, wlan0ap)
local function get_all_devices()

  local devices = {}

  ubusdata = call_ubus_network_device_status()

  for k, v in pairs(ubusdata) do
    table.insert(devices, k)
  end

  return devices
end



-- Get the MAC address (lowercase) of a network device
local function get_device_mac(device)

  local devices = get_all_devices()

  -- Check if the device is a network device
  for k, v in pairs(devices) do
    if device == v then
      local f = io.open(PATH_SYS_CLASS_NET .. v .. "/address")
      if f then
        -- read the MAC address (17 characters: 12 MAC + 5 colons)
        local mac = f:read(17)
        f:close()
        if is_valid_mac(mac) then
          return string.lower(mac)
        end
      end
    end
  end

  return nil
end




-- Get an array with the physical raw Ethernet devices (e.g. eth0, eth1, eth2),
-- excluding wireless and the virtual ones like "lo" (localhost), VLANs, etc.
local function get_ethernet_devices()

  local devices = {}

  ubusdata = call_ubus_network_device_status()

  -- Check all the devices returned by the Ubus call
  for k, v in pairs(ubusdata) do

    -- Check for devices with "Network device" in the "type" field
    for l, w in pairs(v) do

      if l == "type" and w == "Network device" then

        -- Check for virtual devices to discard them
        local f = io.open(PATH_SYS_VIRTUAL_NET .. k)

        if f then
          f:close()
        else

          -- Check for IEEE 802.11 wireless devices to discard them
          local f = io.open(PATH_SYS_CLASS_NET .. k .. "/phy80211")

          if f then
            f:close()
          else
            -- The interface is not VLAN, localhost, wireless, etc.
            table.insert(devices, k)
          end
        end
      end
    end
  end

  return devices
end



-- Get a table with arrays containing the name of the switch and Ethernet devices
-- returned by swconfig (e.g {"switch0"=>"mt7620", "switch1"=>"eth1"}), unfiltered
local function get_etherswitch_swconfig_devices()

  local essdevices = {}

  local f = assert (io.popen ("swconfig list"))

  for line in f:lines() do
    local found = string.find(line, "Found:")
    if found then
      --Get the name of the switch interface (e.g. switch0) from the swconfig output
      local sdev = string.sub(string.sub(line, string.find(line, " ")+1), 0, string.find(string.sub(line, string.find(line, " ")+1)," ")-1)
      --Get the name of the Ethernet interface (e.g. eth0) from the swconfig output
      local edev = string.sub(line, tostring(string.find(line, "-"))+2)
      table.insert(essdevices,{[sdev] = edev});
    end
  end

  f:close()

  return essdevices

end




-- Get the primary network device of the router
local function get_primary_device()

  local edevices = get_ethernet_devices()

  if edevices[1] ~= nil then
    return edevices[1]
  end

  local rdevices = qmp_wireless.get_wireless_radio_devices()

  if rdevices[1] ~= nil then
    return rdevices[1]
  end

  return ("none")
end

-- Get an array with all the VLAN devices (e.g. eth0.1, eth1.7)
local function get_vlan_devices()

  local vdevices = {}

  ubusdata = call_ubus_network_device_status()

  -- Check all the devices returned by the Ubus call
  for k, v in pairs(ubusdata) do

    -- Check for devices with "Network device" in the "type" field
    for l, w in pairs(v) do

      if l == "type" and w == "VLAN" then
        table.insert(vdevices, k)
      end
    end
  end

  return vdevices
end



-- Get a table with arrays containing the name of a VLAN device and the
-- Ethernet device they belong to (e.g {"eth0.1"=>"eth0", "eth1.7"=>"eth1"})
local function get_vlan_ethernet_devices()

  local vedevices = {}
  local vdevices = get_vlan_devices()

  for k, v in pairs(vdevices) do
    local files = qmp_io.ls(PATH_SYS_CLASS_NET .. v)

    for l, w in pairs(files) do
      local lpos = string.find(w, "lower_")

      if lpos then
        table.insert(vedevices,{[v] = string.sub(w, string.find(w, "_")+1)})
      end
    end
  end

  return vedevices
end




-- Get a table with arrays containing the name of a VLAN device and the switched
-- Ethernet device they belong to (e.g {"eth0.1"=>"eth0"})
local function get_vlan_etherswitch_devices()

  local essdevices = {}

  local f = assert (io.popen ("swconfig list"))

  for line in f:lines() do
    local found = string.find(line, "Found:")
    if found then
      --Get the name of the switch interface (e.g. switch0) from the swconfig output
      local sdev = string.sub(string.sub(line, string.find(line, " ")+1), 0, string.find(string.sub(line, string.find(line, " ")+1)," ")-1)
      --Get the name of the Ethernet interface (e.g. eth0) from the swconfig output
      local edev = string.sub(line, tostring(string.find(line, "-"))+2)
      table.insert(essdevices,{[sdev] = edev});
    end
  end

  f:close()
  return essdevices
end



-- Check if a device (e.g. eth4) is an Ethernet device or not
local function is_ethernet_device(edev)

  local edevices = get_ethernet_devices()

  for k, v in pairs(edevices) do
    if edev == v then
      return true
    end
  end

  return false
end


-- Check if a device (e.g. eth4, radio7) is a network device
local function is_network_device(netdev)

  local edevices = get_ethernet_devices()

  for k, v in pairs(edevices) do
    if netdev == v then
      return true
    end
  end

  local rdevices = qmp_wireless.get_wireless_radio_devices()

  for k, v in pairs(rdevices) do
    if netdev == v then
      return true
    end
  end

  return false
end



-- Validate a MAC address
function is_valid_mac(mac)

  if string.len(mac) == 17 then
    if string.match(string.sub(mac,1,2),'[a-zA-Z0-9:][a-zA-Z0-9]') then
      if string.match(string.sub(mac,3,3),':') then
        if string.match(string.sub(mac,4,5),'[a-zA-Z0-9:][a-zA-Z0-9]') then
          if string.match(string.sub(mac,6,6),':') then
            if string.match(string.sub(mac,7,8),'[a-zA-Z0-9:][a-zA-Z0-9]') then
              if string.match(string.sub(mac,9,9),':') then
                if string.match(string.sub(mac,10,11),'[a-zA-Z0-9:][a-zA-Z0-9]') then
                  if string.match(string.sub(mac,12,12),':') then
                    if string.match(string.sub(mac,13,14),'[a-zA-Z0-9:][a-zA-Z0-9]') then
                      if string.match(string.sub(mac,15,15),':') then
                        if string.match(string.sub(mac,16,17),'[a-zA-Z0-9:][a-zA-Z0-9]') then
                          return true
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  return false
end







-- Get a table with arrays containing the name of the switch and Ethernet devices
-- as returned by swconfig, ex.:
--  a) { "switch0"=>"eth0" }
--  b) { "switch0"=>"mt7620", "switch1"=>"eth1" }
--  c) { "switch0"=>"eth0", "switch1"=>"eth0" }
--
-- filtered and matched (best-effort) to the actual Ethernet devices, ex.:
--  a) { "switch0"=>"eth0" }
--  b) { "switch0"=>"eth0", "switch1"=>"eth1" }
--  c) { "switch0"=>"eth0" }
local function get_etherswitch_devices()

  local esdevices = {}
  local repeated = {}
  local unmatched = {}
  local essdevices = get_etherswitch_swconfig_devices()
  local edevices = get_ethernet_devices()

  for a, b in pairs(essdevices) do
    for k, v in pairs(b) do
      -- check if the switch is already listed in esdevices
      local add = true


      for c, d in pairs(esdevices) do
        for l, w in pairs(d) do
          if k == l then
            add = false
          end
        end
      end

      -- the current switch is not yet added
      if add then

        -- check if the pair given by swconfig is an Ethernet device (case a)) and not a strange alias like "mt7620" or "1e180000.etop-ff" (case b))
        if is_ethernet_device(v) then

          -- check that the matched Ethernet device is not already added to esdevices with another switch
          add = true

          for e, f in pairs (esdevices) do
            for m, x in pairs(f) do
              if v == x then
                add = false
              end
            end
          end

          -- add the switch-etherdev pair to esdevices
          if add then
            table.insert(esdevices, {[k] = v})
          -- or add it to the repeated pairs table (case c))?
          else
            repeated[k] = v
          end
        -- swconfig probably returned a strange alias like "mt7620" or "1e180000.etop-ff" (case b))
        else
          unmatched[k] = v
        end

      -- the switch has appeared already, swconfig is returning strange information
      else
        repeated[k] = v
      end
    end
  end

  -- Assign the unmatched switch-ethdev pairs, sequentially, to the Ethernet devices not paired to another switch
  for k, v in pairs(unmatched) do
    -- Test all the Ethernet devices to not be already assigned to a switch
    for l, w in pairs(edevices) do
      add = true

      for a, b in pairs (esdevices) do
        for m, x in pairs (b) do
          if w == x then
            add = false
          end
        end
      end

      if add then
        table.insert(esdevices, {[k] = w})
      end
    end
  end

  return esdevices
end



-- Get the list of Ethernet switch devices (e.g. eth0, eth2)
local function get_ethernet_switch_devices()

  local esdevices = get_etherswitch_devices()
  local edevices = {}

  for a, b in pairs(esdevices) do
    for k, v in pairs(b) do
      table.insert(edevices, v)
    end
  end

  return edevices
end



-- Get the list of switch devices (e.g. switch0, switch1)
local function get_switch_devices()

  local esdevices = get_etherswitch_devices()
  local edevices = {}

  for a, b in pairs(esdevices) do
    for k, v in pairs(b) do
      table.insert(edevices, k)
    end
  end

  return edevices
end


qmp_network.call_ubus_network_device_status = call_ubus_network_device_status
qmp_network.get_all_devices = get_all_devices
qmp_network.get_primary_device = get_primary_device
qmp_network.get_device_mac = get_device_mac
qmp_network.get_ethernet_devices = get_ethernet_devices
qmp_network.get_ethernet_switch_devices = get_ethernet_switch_devices
qmp_network.get_etherswitch_devices = get_etherswitch_devices
qmp_network.get_etherswitch_swconfig_devices = get_etherswitch_swconfig_devices
qmp_network.get_switch_devices = get_switch_devices
qmp_network.get_vlan_devices = get_vlan_devices
qmp_network.get_vlan_ethernet_devices = get_vlan_ethernet_devices
qmp_network.is_ethernet_device = is_ethernet_device
qmp_network.is_network_device = is_network_device
qmp_network.is_valid_mac = is_valid_mac

return qmp_network
