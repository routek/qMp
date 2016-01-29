#!/usr/bin/lua

local OWRT_CONFIG_DIR = "/etc/config/"
local QMP_CONFIG_FILENAME = "qmp"

local qmp_defaults = require("qmp_defaults")
local qmp_io = require("qmp_io")
local qmp_network = qmp_network or require("qmp_network")
local qmp_tools = require("qmp_tools")
local qmp_uci = require("qmp_uci")
local qmp_wireless = require("qmp_wireless")


local qmp_config = {}

local configure_radio_with_criteria
local get_radios_for_criteria
local get_wifi_iface_name
local initialize
local initialize_network



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

    -- Merge the missing values from the defaults
    for k, v in pairs(ndefaults) do
      if not qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "node", k) then
        qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "node", k, v)
      end
    end

    -- Create the devices section or, if already present, add any missing value
    qmp_uci.new_section_typename(QMP_CONFIG_FILENAME, "qmp", "devices")

    -- Add the primary network device
    local primary_device = qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "node", "primary_device")
    if not primary_device or not qmp_network.is_network_device(primary_device) then
      primary_device = qmp_network.get_primary_device()
    end
    qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "devices", "primary_device", primary_device)

    -- Remove parameters from previous versions which no longer must be here
    qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "node", "key", '')
    qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "node", "primary_device", '')
  end

  initialize_devices()
end


-- Initialize the qMp configuration file with the network devices in their interfaces
function initialize_devices(force)

  -- Check if the configuration file exists
  if not qmp_io.is_file(OWRT_CONFIG_DIR .. QMP_CONFIG_FILENAME) then
  os.exit(1)
  end

  -- Create the network section if not already there
  qmp_uci.new_section_typename(QMP_CONFIG_FILENAME, "qmp", "devices")

  -- Get previously configured interfaces in older qMp versions and wipe out old stuff
  local old_lan_devices = qmp_tools.list_to_array(qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "interfaces", "lan_devices"))
  local old_wan_devices = qmp_tools.list_to_array(qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "interfaces", "wan_devices"))
  local old_mesh_devices = qmp_tools.list_to_array(qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "interfaces", "mesh_devices"))
  local old_ignore_devices = qmp_tools.list_to_array(qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "interfaces", "ignore_devices"))
  local old_no_vlan_devices = qmp_tools.list_to_array(qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "interfaces", "no_vlan_devices"))

  -- qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "interfaces", "lan_devices")
  -- qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "interfaces", "wan_devices")
  -- qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "interfaces", "mesh_devices")
  -- qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "interfaces", "ignore_devices")
  -- qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "interfaces", "no_vlan_devices")
  -- TODO: remove the old interfaces section

  -- The following categories are used:
  local lan_devices = qmp_tools.array_unique(qmp_tools.list_to_array(qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "devices", "lan_devices")))
  local wan_devices = qmp_tools.array_unique(qmp_tools.list_to_array(qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "devices", "wan_devices")))
  local mesh_devices = qmp_tools.array_unique(qmp_tools.list_to_array(qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "devices", "mesh_devices")))
  local ignore_devices = qmp_tools.array_unique(qmp_tools.list_to_array(qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "devices", "ignore_devices")))
  local no_vlan_devices = qmp_tools.array_unique(qmp_tools.list_to_array(qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "devices", "no_vlan_devices")))
  local switch_devices = qmp_tools.array_unique(qmp_tools.list_to_array(qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "devices", "switch_devices")))

  if force then
    local lan_devices = {}
    local wan_devices = {}
    local mesh_devices = {}
    local ignore_devices = {}
    local novlan_devices = {}
    local switch_devices = {}
  end

  -- Configure Ethernet devices
  -- Get the lists of Ethernet devices, switched Ethernet devices, swithed Ethernet VLANs and all VLANs
  local edevices = qmp_network.get_ethernet_devices()
  local esdevices = qmp_network.get_ethernet_switch_devices()
  local vesdevices = qmp_network.get_vlan_ethernet_devices()
  local vdevices = qmp_network.get_vlan_devices()

  local eth_to_configure = {}
  local eth_configured = {}

  -- Run through all the Ethernet devices
  for k, v in pairs(edevices) do

    -- Check if the device has a switch
    if qmp_network.is_ethernet_switched_device(v) then

      -- Mark the device as switch only if there are switched VLANs on the device
      local vlans = false

      for l, w in pairs(vesdevices) do
        for m, x in pairs(w) do
          if x == v then
            vlans = true
          end
        end
      end

      if vlans then
        table.insert(switch_devices, v)
        table.insert(ignore_devices, v)
        table.insert(eth_configured, v)
      else
        table.insert(eth_to_configure, v)
      end

    else
      table.insert(eth_to_configure, v)
    end

    -- Run through all the VLANs to check if they belong to the current Ethernet interface
    for l, w in pairs(vesdevices) do
      for m, x in pairs(w) do

        -- If the VLAN belongs to the switched Ethernet interface add it to the list of device to configure
        if x == v then
          table.insert(eth_to_configure, m)
        end
      end
    end
  end

  -- Run through all the VLANs to check if any VLAN not attached to an Ethernet switch is missing (e.g. br-lan.33)
  for k, v in pairs(vdevices) do
    if not qmp_tools.is_item_in_array(v, eth_to_configure) then
      table.insert(eth_to_configure, v)
    end
  end

  -- TODO: detect IPIP tunnels and process them here to!

  local added_lan = false
  local added_wan = false

  -- The logic to configure Ethernet devices goes as follows:
  --
  -- If the device was already configured, leave whatever configuration it had. If it
  -- wasn't, the roles assignation priority is 1 LAN, 1 WAN, n LAN:
  --  · At least one device in the bridge LAN
  --  · If more devices available, at least one device as WAN
  --  · All other devices in the bridge LAN
  --  · Use them for meshing by default

  -- First, apply settings from older qMp releases
  for k, v in pairs(eth_to_configure) do
     -- Check if the device is already configured as ignore, lan or wan
    if qmp_tools.is_item_in_array(v, old_ignore_devices) then
      table.insert(ignore_devices, v)
      table.insert(eth_configured, v)
    elseif qmp_tools.is_item_in_array(v, old_lan_devices) then
      table.insert(lan_devices, v)
      table.insert(eth_configured, v)
      added_lan = true
    elseif qmp_tools.is_item_in_array(v, old_wan_devices) then
      table.insert(wan_devices, v)
      table.insert(eth_configured, v)
      added_wan = true
    end

    if qmp_tools.is_item_in_array(v, old_mesh_devices) then
      table.insert(mesh_devices, v)
      table.insert(eth_configured, v)
    end

    if qmp_tools.is_item_in_array(v, old_novlan_devices) then
      table.insert(novlan_devices, v)
      table.insert(eth_configured, v)
    end
  end

  -- Check if the device is in the current configuration
  for k, v in pairs(eth_to_configure) do
    if not qmp_tools.is_item_in_array(v, eth_configured) then

      if qmp_tools.is_item_in_array(v, ignore_devices) then
        table.insert(eth_configured, v)
      elseif qmp_tools.is_item_in_array(v, lan_devices) then
        table.insert(eth_configured, v)
        added_lan = true
      elseif qmp_tools.is_item_in_array(v, wan_devices) then
        table.insert(eth_configured, v)
        added_wan = true
      end

      if qmp_tools.is_item_in_array(v, mesh_devices) then
        table.insert(eth_configured, v)
      end

      if qmp_tools.is_item_in_array(v, novlan_devices) then
        table.insert(eth_configured, v)
      end

    end
  end

  -- Add any device remaining unconfigured
  for k, v in pairs(eth_to_configure) do
    if not qmp_tools.is_item_in_array(v, eth_configured) then

      if not added_lan then
        table.insert(lan_devices, v)
        table.insert(eth_configured, v)
        added_lan = true
      elseif not added_wan then
        table.insert(wan_devices, v)
        table.insert(eth_configured, v)
        added_wan = true
      else
        table.insert(lan_devices, v)
        table.insert(eth_configured, v)
      end

      table.insert(mesh_devices, v)

    end
  end

  -- Save
  qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "devices", "lan_devices", qmp_tools.array_to_list(qmp_tools.array_unique(lan_devices)))
  qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "devices", "wan_devices", qmp_tools.array_to_list(qmp_tools.array_unique(wan_devices)))
  qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "devices", "mesh_devices", qmp_tools.array_to_list(qmp_tools.array_unique(mesh_devices)))
  qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "devices", "ignore_devices", qmp_tools.array_to_list(qmp_tools.array_unique(ignore_devices)))
  qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "devices", "novlan_devices", qmp_tools.array_to_list(qmp_tools.array_unique(novlan_devices)))
  qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "devices", "switch_devices", qmp_tools.array_to_list(qmp_tools.array_unique(switch_devices)))


  -- Configure wireless devices
  -- Get the lists of wireless devices
  local allradios = qmp_wireless.get_wireless_radio_devices()
  local confradios = {}

  -- Wireless configuration criteria
  --
  -- 1) 5 GHz in adhoc_mesh mode
  -- 2) 2.4 GHz in AP_lan and 80211s_mesh modes
  -- 3) 5 GHz in AP_lan mode (lowest channel +)
  -- 4) 2.4 GHz in AP_lan and 80211s_mesh modes

  local criteria = {}

    criteria[1] = {}
    criteria[1]["selected"] = nil
    criteria[1]["band"] = "5g"
    criteria[1]["channel"] = 1
    criteria[1]["configs"] = {}
      criteria[1]["configs"][1] = {}
      criteria[1]["configs"][1]["phymode"] = "adhoc"
      criteria[1]["configs"][1]["netmode"] = "mesh"

    criteria[2] = {}
    criteria[2]["selected"] = nil
    criteria[2]["band"] = "2g"
    criteria[2]["channel"] = 1
    criteria[2]["configs"] = {}
      criteria[2]["configs"][1] = {}
      criteria[2]["configs"][1]["phymode"] = "ap"
      criteria[2]["configs"][1]["netmode"] = "lan"
      criteria[2]["configs"][2] = {}
      criteria[2]["configs"][2]["phymode"] = "mesh"
      criteria[2]["configs"][2]["netmode"] = "mesh"

    criteria[3] = {}
    criteria[3]["selected"] = nil
    criteria[3]["band"] = "5g"
    criteria[3]["channel"] = -1
    criteria[3]["configs"] = {}
      criteria[3]["configs"][1] = {}
      criteria[3]["configs"][1]["phymode"] = "ap"
      criteria[3]["configs"][1]["netmode"] = "lan"

    criteria[4] = {}
    criteria[4]["selected"] = nil
    criteria[4]["band"] = "2g"
    criteria[4]["channel"] = -1
    criteria[4]["configs"] = {}
      criteria[4]["configs"][1] = {}
      criteria[4]["configs"][1]["phymode"] = "ap"
      criteria[4]["configs"][1]["netmode"] = "lan"
      criteria[4]["configs"][2] = {}
      criteria[4]["configs"][2]["phymode"] = "mesh"
      criteria[4]["configs"][2]["netmode"] = "mesh"



  for k, v in pairs(criteria) do
    print ("")
    print ("Criteria " .. k)

    if v["selected"] == nil then
      local possradios = get_radios_free_for_criteria (v, confradios)

      for ak, av in pairs(possradios) do
        print ("Candidates: " .. av)
      end

      local selradio = nil

      if table.getn(possradios) == 1 then
        selradio = possradios[1]
      elseif table.getn(possradios) >= 1 then
        for l, m in pairs(possradios) do
          if selradio == nil and qmp_wireless.is_radio_band(m,v["band"]) and not qmp_wireless.is_radio_band_dual(m) then
            selradio = m
          end
        end
      end

      if selradio == nil and table.getn(possradios) >= 1 then
        selradio = possradios[1]
      end

      if selradio ~= nil then
        print ("Selected: " .. selradio)
        table.insert(confradios, selradio)
        configure_radio_with_criteria(selradio, v)
      end

    end

  end







end


-- Configure a radio device with a criteria
function configure_radio_with_criteria(radio, criteria)

  local iw = qmp_wireless.get_radio_iwinfo(radio)

  print ("Configuring " .. radio .. " with the follwing criteria:")
  for k, v in pairs(criteria) do
    if type(v) == table then
      for l, m in pairs(v) do
        print (k .. "." .. l .. tostring(v))
      end
    else
      print (k .. ": " .. tostring(v))
    end
  end

  -- Create the section for the radio device
  qmp_uci.new_section_typename(QMP_CONFIG_FILENAME, "wifi-device", radio)
  -- Set the channel
  print("Criteria->channel: " .. criteria["channel"])

  if criteria["channel"] < 0 then
    criteria["channel"] = table.getn(iw.freqlist) + criteria["channel"]
  end

  local channel = iw.freqlist[criteria["channel"]]["channel"]
  print ("Channel: " .. channel)
  qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, radio, "channel", channel)

  local macaddr = qmp_wireless.get_device_mac(radio)
  print ("MAC address: " .. macaddr)
  qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, radio, "macaddr", macaddr)


  -- Configure the wifi-ifaces
  for k, v in pairs(criteria["configs"]) do
    print ("Configuring a wifi-iface in " .. v["phymode"] .. " mode for " .. radio .. ":")

    -- Create the section for the radio device
    local name = get_wifi_iface_name(radio, v["phymode"])
    qmp_uci.new_section_typename(QMP_CONFIG_FILENAME, "wifi-iface", name)

    -- Specify which radio it belongs to
    qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, name, "device", radio)

    -- Specify the operation mode
    qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, name, "phymode", v["phymode"])

  end
end



-- Get the name for a wifi-iface for a given radio and mode
function get_wifi_iface_name(radio, mode)

  local number = string.match(radio, "%d+")

  if mode == "adhoc" then
    return ("wlan" .. number)
  elseif mode == "80211s" then
    return ("wlan" .. number .. "s")
  else
    return ("wlan" .. number .. mode)
  end
end



-- Get an array with the radios that meet the given criteria
function get_radios_for_criteria (crit)
  return qmp_wireless.get_radios_band(crit["band"])
end



-- Get an array with available radios that meet the given criteria
function get_radios_free_for_criteria (crit, confradios)

  local cradios = get_radios_for_criteria(crit)

  local fradios = {}

  for k,v in pairs(cradios) do
    if not qmp_tools.is_item_in_array(v, confradios) then
      table.insert(fradios, v)
    end
  end

  return fradios
end


-- Set the given role to a network device
function set_device_role(dev, role)

  -- Check if the configuration file exists
  if not qmp_io.is_file(OWRT_CONFIG_DIR .. QMP_CONFIG_FILENAME) then
  os.exit(1)
  end

  -- Create devices section, if missing
  qmp_uci.new_section_typename(QMP_CONFIG_FILENAME, "qmp", "devices")

  -- Get current roles
  local lan_devices = qmp_tools.list_to_array(qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "devices", "lan_devices"))
  local wan_devices = qmp_tools.list_to_array(qmp_uci.get_option_namesec(QMP_CONFIG_FILENAME, "devices", "wan_devices"))

  -- Remove device from any role
  if role == "lan" or role == "wan" or role == "none" then
    lan_devices = qmp_tools.remove_item_from_array(dev, lan_devices)
    wan_devices = qmp_tools.remove_item_from_array(dev, wan_devices)
  end

  -- Set the device in the new role
  if role == "lan" then
    table.insert(lan_devices, dev)
  elseif role == "wan" then
    table.insert(wan_devices, dev)
  end

  qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "devices", "lan_devices", qmp_tools.array_to_list(lan_devices))
  qmp_uci.set_option_namesec(QMP_CONFIG_FILENAME, "devices", "wan_devices", qmp_tools.array_to_list(wan_devices))
end


qmp_config.configure_radio_with_criteria = configure_radio_with_criteria
qmp_config.get_radios_for_criteria = get_radios_for_criteria
qmp_config.initialize = initialize
qmp_config.initialize_network = initialize_network
qmp_config.set_device_role = set_device_role

return qmp_config

