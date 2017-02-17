#!/usr/bin/lua

qmp_bmx6     = qmp_bmx6     or require("qmp.bmx6")
qmp_config   = qmp_config   or require("qmp.config")
qmp_io       = qmp_io       or require("qmp.io")
qmp_ipv4     = qmp_ipv4     or require("qmp.ipv4")
qmp_network  = qmp_network  or require("qmp.network")
qmp_system   = qmp_system   or require("qmp.system")
qmp_tools    = qmp_tools    or require("qmp.tools")
qmp_uci      = qmp_uci      or require("qmp.uci")
qmp_wireless = qmp_wireless or require("qmp.wireless")

function print_help()
        print("qmp4lib is a handy script library that provides information about this qMp device\
  and the mesh status. It is mostly thought for development.")
        print("")
        print("Usage: qmp4lib <section> <command> [options]")
        print("")
        print("Available sections and commands:")
        print("")
        print(" bmx6")
        print("  configure_tmain                                 : configure tmain tunDev device")
        print("")
        print(" config")
        print("  set_device_role <device> <role>                 : set a device the specified qMp role")
        print("")
        print(" io")
        print("  read_file <filename>                            : print the content of a file")
        print("")
        print(" ipv4")
        print("  netmask_cidr_to_full <netmask>                 : convert a CIDR netmask to a full-length netmask")
        print("  netmask_full_to_cidr <netmask>                 : convert a full-length netmask to a CIDR netmask")
        print("")
        print(" network")
        print("  get_device_mac <device>                         : get a network device's MAC address")
        print("  get_primary_device                              : get the primary network device")
        print("  is_device <device>                              : check if a device (e.g. eth0, radio1) is a network device")
        print("  is_ethernet_device <device>                     : check if a device (e.g. eth0) is an Ethernet network device")
        print("  is_ethernet_switched_device <device>            : check if a device (e.g. eth0) is an Ethernet network device with a switch")
        print("  is_valid_mac <mac>                              : check if a MAC address (e.g. \"02:CA:FF:EE:BA:BE\") is valid")
        print("  list_all_devices                                : print the list of all network devices")
        print("  list_ethernet_devices                           : print the list of Ethernet network devices")
        print("  list_ethernet_switch_devices                    : print the list of Ethernet network devices with a switch")
        print("  list_switch_devices                             : print the list of Ethernet network devices")
        print("  list_vlan_devices                               : print the list of VLAN network devices")
        print("  table_etherswitch_devices                       : print the table of Ethernet network devices with a switch")
        print("  table_etherswitch_swconfig_devices              : print the table of Ethernet network devices with a switch as returned by swconfig")
        print("  table_vlan_ethernet_devices                     : print the table of the VLAN network devices and their lower Ethernet device")
        print("")
        print(" system")
        print("  generate_key                                    : generate a qMp mesh key")
        print("  get_community_id                                : get the device's community id")
        print("  get_node_id                                     : get the device's node id")
        print("  get_primary_device                              : get the device's configured primary device")
        print("  set_system_hostname <hostname>                  : set the system hostname specified by hostname")
        print("")
        print(" uci")
        print("  count_typesec <file> <type>                     : count the number of sections of a type in a file")
        print("  get_namesec <file> <type> <op>                  : get an option in a named section of a file")
        print("  delete_namesec <file> <name>                    : delete the section with the given name in a file")
        print("  delete_typesecs_by_opval <file> <type> <op> <value>  : delete all sections of a given type in a file containing an option of a certain name and value")
        print("  get_nonamesec <file> <type> <index> <op>        : get an option in an indexed unnamed section of a file")
        print("  new_section_typename <file> <type> <name>       : create a new uci section of the given type and name in a file")
        print("  set_namesec <file> <type> <op> <val>            : set an option in a named section of a file")
        print("  set_nonamesec <file> <type> <index> <op> <val>  : set an option in an indexed unnamed section of a file")
        print("  set_typenamesec <file> <type> <name> <op> <val> : set an option in named section of a type in a file")
        print("")
        print(" wireless")
        print("  configure_wifi_device <device>                  : configure /etc/config/wireless for a wireless device already configured in /etc/config/qmp)")
        print("  configure_wifi_iface <interfaces>               : configure /etc/config/wireless for a wireless interface already configured in /etc/config/qmp)")
        print("  delete_wifi_ifaces <device>                     : delete all wireless interfaces for a wireless device in /etc/config/wireless)")
        print("  get_radio_channels <device> [band]              : get the channels a radio device (e.g. radio0) can use, optionally specifying the band (2g or 5g)")
        print("  get_radio_hwmode <device>                       : get the hwmode info of a radio device")
        print("  get_radios_band_2g                              : get the wireless radios that work on the 2.4 GHz band")
        print("  get_radios_band_5g                              : get the wireless radios that work on the 5 GHz band")
        print("  get_radios_band_dual                            : get the wireless radios that work on both the 5 and 2.4 GHz bands")
        print("  is_radio_device <device>                        : check if a device (e.g. radio0) is a wireless radio device")
        print("  is_radio_band <device> <band>                   : check if a wireless radio device (e.g. radio0) works on the given band (2g or 5g)")
        print("  is_radio_band_2g <device>                       : check if a wireless radio device (e.g. radio0) works on the 2.4 GHz band")
        print("  is_radio_band_5g <device>                       : check if a wireless radio device (e.g. radio0) works on the 5 GHz band")
        print("  is_radio_band_dual <device>                     : check if a wireless radio device (e.g. radio0) works on both the 5 and 2.4 GHz bands")
        print("  list_physical_devices                           : print the list of wireless physical devices")
        print("  list_radio_devices                              : print the list of wireless radio devices")





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


function check_wireless_radio_band()
  if #arg == 4 then
    print (tostring(qmp_wireless.is_radio_band(arg[3], arg[4])))
  else
    print_help()
    os.exit(1)
  end
end


function generate_system_key()
  print (qmp_system.generate_key())
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


function get_tools_random_hex_string()
  if #arg == 3 then
    print ((qmp_tools.get_random_hex(tonumber(arg[3]))))
  else
    print_help()
    os.exit(1)
  end
end


function count_uci_typesec()
  if #arg == 4 then
    print (qmp_uci.count_typesec(arg[3], arg[4]))
  else
    print_help()
    os.exit(1)
  end
end


function del_uci_namesec()
  if #arg == 4 then
    print (qmp_uci.delete_namesec(arg[3], arg[4]))
  else
    print_help()
    os.exit(1)
  end
end


function del_uci_typesecs_by_opval()
  if #arg == 6 then
    print (qmp_uci.delete_typesecs_by_option_value(arg[3], arg[4], arg[5], arg[6]))
  else
    print_help()
    os.exit(1)
  end
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
    result = qmp_uci.get_option_nonamesec(arg[3], arg[4], arg[5], arg[6])
    for k, v in pairs (result) do
      print (k .. v)
    end
    print (result)
  else
    print_help()
    os.exit(1)
  end
end


function config_bmx6_tmain()
  if #arg == 2 then
    print (qmp_bmx6.configure_tmain(arg[3]))
  else
    print_help()
    os.exit(1)
  end
end


function config_wireless_wifi_device()
  if #arg == 3 then
    print (qmp_wireless.configure_wifi_device(arg[3]))
  else
    print_help()
    os.exit(1)
  end
end


function config_wireless_wifi_iface()
  if #arg == 3 then
    print (qmp_wireless.configure_wifi_iface(arg[3]))
  else
    print_help()
    os.exit(1)
  end
end


function del_wireless_wifi_ifaces()
  if #arg == 3 then
    print (qmp_wireless.delete_wifi_ifaces(arg[3]))
  else
    print_help()
    os.exit(1)
  end
end


function netmask_ipv4_cidr_to_full()
  if #arg == 3 then
    print (qmp_ipv4.netmask_cidr_to_full(arg[3]))
  else
    print_help()
    os.exit(1)
  end
end


function netmask_ipv4_full_to_cidr()
  if #arg == 3 then
    print (qmp_ipv4.netmask_full_to_cidr(arg[3]))
  else
    print_help()
    os.exit(1)
  end
end


function get_wireless_radio_channels()
  if #arg == 3 or #arg == 4 then
    local channels = qmp_wireless.get_radio_channels(arg[3], arg[4])
    for k, v in pairs (channels) do
      print (v)
    end
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


function read_io_file()
  if #arg == 3 then
    for k, v in pairs(qmp_io.read_file(arg[3])) do
      print (v)
    end
  else
    print_help()
    os.exit(1)
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


if section == "bmx6" then

  if command == "configure_tmain" then
    config_bmx6_tmain()
  end


elseif section == "config" then

  if command == "set_config_device_role" then
    set_config_device_role()
  end


elseif section == "io" then

  if command == "read_file" then
    read_io_file()
  end


elseif section == "ipv4" then

  if command == "netmask_cidr_to_full" then
    netmask_ipv4_cidr_to_full()

  elseif command == "netmask_full_to_cidr" then
    netmask_ipv4_full_to_cidr()
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

  if command == "generate_key" then
    generate_system_key()

  elseif command == "get_community_id" then
    get_system_community_id()

  elseif command == "get_node_id" then
    get_system_node_id()

  elseif command == "get_primary_device" then
    get_system_primary_device()

  elseif command == "set_hostname" then
    set_system_hostname()
  end


elseif section == "tools" then

  if command == "get_random_hex_string" then
    get_tools_random_hex_string()
  end


elseif section == "uci" then

  if command == "count_typesec" then
    count_uci_typesec()

  elseif command == "delete_namesec" then
    del_uci_namesec()

  elseif command == "delete_typesecs_by_opval" then
    del_uci_typesecs_by_opval()

  elseif command == "get_namesec" then
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

  if command == "configure_wifi_device" then
    config_wireless_wifi_device()

  elseif command == "configure_wifi_iface" then
    config_wireless_wifi_iface()

  elseif command == "delete_wifi_ifaces" then
    del_wireless_wifi_ifaces()

  elseif command == "get_radio_channels" then
    get_wireless_radio_channels()

  elseif command == "get_radio_hwmode" then
    get_wireless_radio_hwmode()

  elseif command == "get_radios_band_2g" then
    get_wireless_radios_band_2g()

  elseif command == "get_radios_band_5g" then
    get_wireless_radios_band_5g()

  elseif command == "get_radios_band_dual" then
    get_wireless_radios_band_dual()

  elseif command == "is_radio_device" then
    check_is_wireless_radio_device()

  elseif command == "is_radio_band" then
    check_wireless_radio_band()

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
