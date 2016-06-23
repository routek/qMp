#!/usr/bin/lua

qmp_config   = qmp_config   or require("qmp.config")
qmp_network  = qmp_network  or require("qmp.network")
qmp_system   = qmp_system   or require("qmp.system")
qmp_uci      = qmp_uci      or require("qmp.uci")
qmp_wireless = qmp_wireless or require("qmp.wireless")

function print_help()
        print("qmplib is a handy script library that provides information about this qMp device\
  and the mesh status. It is mostly thought for development.")
        print("")
        print("Usage: qmplib <section> <command> [options]")
        print("")
        print("Available sections and commands:")
        print("")
        print(" config")
        print("  set_device_role <device> <role>     : set a device the specified qMp role")
        print("")
        print(" network")
        print("  device_mac <device>                        : get a network device's MAC address")
        print("  get_primary_device                         : get the primary network device")
        print("  is_device <device>                         : check if a device (e.g. eth0, radio1) is a network device")
        print("  is_ethernet_device <device>                : check if a device (e.g. eth0) is an Ethernet network device")
        print("  is_ethernet_switched_device <device>       : check if a device (e.g. eth0) is an Ethernet network device with a switch")
        print("  is_valid_mac <mac>                         : check if a MAC address (e.g. \"02:CA:FF:EE:BA:BE\") is valid")
        print("  list_all_devices                           : print the list of all network devices")
        print("  list_ethernet_devices                      : print the list of Ethernet network devices")
        print("  list_ethernet_switch_devices               : print the list of Ethernet network devices with a switch")
        print("  list_switch_devices                        : print the list of Ethernet network devices")
        print("  list_vlan_devices                          : print the list of VLAN network devices")
        print("  table_etherswitch_devices                  : print the table of Ethernet network devices with a switch")
        print("  table_etherswitch_swconfig_devices         : print the table of Ethernet network devices with a switch as returned by swconfig")
        print("  table_vlan_ethernet_devices                : print the table of the VLAN network devices and their lower Ethernet device")
        print("")
        print(" system")
        print("  get_community_id                           : get the device's community id")
        print("  get_node_id                                : get the device's node id")
        print("  get_primary_device                         : get the device's configured primary device")
        print("  set_system_hostname <hostname>             : set the system hostname specified by hostname")
        print("")
        print(" uci")
        print("  get_namesec <file> <type> <op>                  : get an option in a named section of a file")
        print("  get_nonamesec <file> <type> <index> <op>        : get an option in an indexed unnamed section of a file")
        print("  new_section_typename <file> <type> <name>       : create a new uci section of the given type and name in a file")
        print("  set_namesec <file> <type> <op> <val>            : set an option in a named section of a file")
        print("  set_nonamesec <file> <type> <index> <op> <val>  : set an option in an indexed unnamed section of a file")
        print("  set_typenamesec <file> <type> <name> <op> <val> : set an option in named section of a type in a file")
        print("")
        print(" wireless")
        print("  get_radio_hwmode <device>                 : get the hwmode info of a radio device")
        print("  get_radios_band_2g                        : get the wireless radios that work on the 2.4 GHz band")
        print("  get_radios_band_5g                        : get the wireless radios that work on the 5 GHz band")
        print("  get_radios_band_dual                      : get the wireless radios that work on both the 5 and 2.4 GHz bands")
        print("  is_radio_device <device>                  : check if a device (e.g. radio0) is a wireless radio device")
        print("  is_radio_band_2g <device>                 : check if a wireless radio device (e.g. radio0) works on the 2.4 GHz band")
        print("  is_radio_band_5g <device>                 : check if a wireless radio device (e.g. radio0) works on the 5 GHz band")
        print("  is_radio_band_dual <device>               : check if a wireless radio device (e.g. radio0) works on both the 5 and 2.4 GHz bands")
        print("  list_physical_devices                     : print the list of wireless physical devices")
        print("  list_radio_devices                        : print the list of wireless radio devices")





        print("")
end


function check_is_network_device()
  if #arg == 3 then
    print (tostring(qmp_network.is_network_device(arg[3])))
  else
    print_help()
    os.exit(1)
  end
end


function check_is_network_ethernet_device()
  if #arg == 3 then
    print (tostring(qmp_network.is_ethernet_device(arg[3])))
  else
    print_help()
    os.exit(1)
  end
end



function check_is_network_ethernet_switched_device()
  if #arg == 3 then
    print (tostring(qmp_network.is_ethernet_switched_device(arg[3])))
  else
    print_help()
    os.exit(1)
  end
end


function check_is_wireless_radio_device()
  if #arg == 3 then
    print (tostring(qmp_wireless.is_radio_device(arg[3])))
  else
    print_help()
    os.exit(1)
  end
end


function check_is_wireless_radio_2g()
  if #arg == 3 then
    print (tostring(qmp_wireless.is_radio_band_2g(arg[3])))
  else
    print_help()
    os.exit(1)
  end
end


function check_is_wireless_radio_5g()
  if #arg == 3 then
    print (tostring(qmp_wireless.is_radio_band_5g(arg[3])))
  else
    print_help()
    os.exit(1)
  end
end


function check_is_wireless_radio_dual()
  if #arg == 3 then
    print (tostring(qmp_wireless.is_radio_band_dual(arg[3])))
  else
    print_help()
    os.exit(1)
  end
end


function create_new_uci_section_typename()
  if #arg == 5 then
    qmp_uci.new_section_typename(arg[3], arg[4], arg[5])
  else
    print_help()
    os.exit(1)
  end
end


function get_network_primary_device()
  print (tostring(qmp_network.get_primary_device()))
end


function check_is_network_valid_mac()
  if #arg == 3 then
    print (tostring(qmp_network.is_valid_mac(arg[3])))
  else
    print_help()
    os.exit(1)
  end
end


function get_network_device_mac()
  if #arg == 3 then
    print ((qmp_network.get_device_mac(arg[3])))
  else
    print_help()
    os.exit(1)
  end
end


function get_system_community_id()
  print (qmp_system.get_community_id())
end


function get_system_node_id()
  print (qmp_system.get_node_id())
end


function get_system_primary_device()
  print (tostring(qmp_system.get_primary_device()))
end


function get_uci_namesec()
  if #arg == 5 then
    print (qmp_uci.get_option_namesec(arg[3], arg[4], arg[5]))
  else
    print_help()
    os.exit(1)
  end
end


function get_uci_nonamesec()
  if #arg == 6 then
    print (qmp_uci.get_option_nonamesec(arg[3], arg[4], arg[5], arg[6]))
  else
    print_help()
    os.exit(1)
  end
end


function get_wireless_radio_hwmode()
  if #arg == 3 then
    local iw = qmp_wireless.get_radio_iwinfo(arg[3])
    for k, v in pairs (iw.hwmodelist) do
      print (k .. ": " .. tostring(v))
    end
  else
    print_help()
    os.exit(1)
  end
end


function get_wireless_radios_band_2g()
  for k, v in pairs (qmp_wireless.get_radios_band_2g()) do
    print (k .. ": " .. v)
  end
end


function get_wireless_radios_band_5g()
  for k, v in pairs (qmp_wireless.get_radios_band_5g()) do
    print (k .. ": " .. v)
  end
end


function get_wireless_radios_band_dual()
  for k, v in pairs (qmp_wireless.get_radios_band_dual()) do
    print (k .. ": " .. v)
  end
end


function print_list_network_all_devices()
  for k, v in pairs(qmp_network.get_all_devices()) do
    print (v)
  end
end


function print_list_network_ethernet_devices()
  for k, v in pairs(qmp_network.get_ethernet_devices()) do
    print (v)
  end
end


function print_list_network_ethernet_switch_devices()
  for k, v in pairs(qmp_network.get_ethernet_switch_devices()) do
    print (v)
  end
end


function print_list_network_switch_devices()
  for k, v in pairs(qmp_network.get_switch_devices()) do
    print (v)
  end
end


function print_list_network_vlan_devices()
  for k, v in pairs(qmp_network.get_vlan_devices()) do
    print (v)
  end
end


function print_list_wireless_physical_devices()
  for k, v in pairs(qmp_wireless.get_wireless_phy_devices()) do
    print (v)
  end
end


function print_list_wireless_radio_devices()
  for k, v in pairs(qmp_wireless.get_wireless_radio_devices()) do
    print (v)
  end
end


function print_table_network_etherswitch_devices()
  for k, v in pairs(qmp_network.get_etherswitch_devices()) do
    for l, w in pairs(v) do
      print (k .. ": " .. l .. ": " .. w)
    end
  end
end


function print_table_network_etherswitch_swconfig_devices()
  for k, v in pairs(qmp_network.get_etherswitch_swconfig_devices()) do
    for l, w in pairs(v) do
      print (k .. ": " .. l .. ": " .. w)
    end
  end
end


function print_table_network_vlan_ethernet_devices()
  for k, v in pairs(qmp_network.get_vlan_ethernet_devices()) do
    for l, w in pairs(v) do
      print (k .. ": " .. l .. ": " .. w)
    end
  end
end


function set_config_device_role()
  if #arg == 4 then
    qmp_config.set_device_role(arg[3], arg[4])
  else
    print_help()
    os.exit(1)
  end
end


function set_system_hostname()
  if #arg == 3 then
    qmp_system.set_hostname(arg[3])
  else
    print_help()
    os.exit(1)
  end
end


function set_uci_namesec()
  if #arg == 6 then
    qmp_uci.set_option_namesec(arg[3], arg[4], arg[5], arg[6])
  else
    print_help()
    os.exit(1)
  end
end


function set_uci_nonamesec()
  if #arg == 7 then
    qmp_uci.set_option_nonamesec(arg[3], arg[4], arg[5], arg[6], arg[7])
  else
    print_help()
    os.exit(1)
  end
end


function set_uci_typenamesec()
  if #arg == 7 then
    qmp_uci.set_option_typenamesec(arg[3], arg[4], arg[5], arg[6], arg[7])
  else
    print_help()
    os.exit(1)
  end
end



if #arg < 2 then
        print_help()
        os.exit(1)
end

local section = arg[1]
local command = arg[2]

if section == "config" then

  if command == "set_config_device_role" then
    set_config_device_role()
  end



elseif section == "network" then

  if command == "get_device_mac" then
    get_network_device_mac()

  elseif command == "get_primary_device" then
    get_network_primary_device()

  elseif command == "is_ethernet_device" then
    check_is_network_ethernet_device()

  elseif command == "is_ethernet_switched_device" then
    check_is_network_ethernet_switched_device()

  elseif command == "is_device" then
    check_is_network_device()

  elseif command == "is_valid_mac" then
    check_is_network_valid_mac()

  elseif command == "list_all_devices" then
    print_list_network_all_devices()

  elseif command == "list_ethernet_devices" then
    print_list_network_ethernet_devices()

  elseif command == "list_ethernet_switch_devices" then
    print_list_network_ethernet_switch_devices()

  elseif command == "list_switch_devices" then
    print_list_network_switch_devices()

  elseif command == "list_vlan_devices" then
    print_list_network_vlan_devices()

  elseif command == "table_etherswitch_devices" then
    print_table_network_etherswitch_devices()

  elseif command == "table_etherswitch_swconfig_devices" then
    print_table_network_etherswitch_swconfig_devices()

  elseif command == "table_vlan_ethernet_devices" then
    print_table_network_vlan_ethernet_devices()
  end



elseif section == "system" then

  if command == "get_community_id" then
    get_system_community_id()

  elseif command == "get_node_id" then
    get_system_node_id()

  elseif command == "get_primary_device" then
    get_system_primary_device()

  elseif command == "set_hostname" then
    set_system_hostname()
  end



elseif section == "uci" then

  if command == "get_namesec" then
    get_uci_namesec()

  elseif command == "get_nonamesec" then
    get_uci_nonamesec()

  elseif command == "set_section_typename" then
    set_uci_namesec()

  elseif command == "set_typenamesec" then
    set_uci_typenamesec()

  elseif command == "set_nonamesec" then
    set_uci_nonamesec()
  end



elseif section == "wireless" then

  if command == "get_radio_hwmode" then
    get_wireless_radio_hwmode()

  elseif command == "get_radios_band_2g" then
    get_wireless_radios_band_2g()

  elseif command == "get_radios_band_5g" then
    get_wireless_radios_band_5g()

  elseif command == "get_radios_band_dual" then
    get_wireless_radios_band_dual()

  elseif command == "is_radio_device" then
    check_is_wireless_radio_device()

  elseif command == "is_radio_band_2g" then
    check_is_wireless_radio_2g()

  elseif command == "is_radio_band_5g" then
    check_is_wireless_radio_5g()

  elseif command == "is_radio_band_dual" then
    check_is_wireless_radio_dual()

  elseif command == "list_physical_devices" then
    print_list_wireless_physical_devices()

  elseif command == "list_radio_devices" then
    print_list_wireless_radio_devices()
  end

else
  print_help()
end
