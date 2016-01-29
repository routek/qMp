#!/usr/bin/lua

qmp_config   = qmp_config   or require("qmp_config")
qmp_defaults = qmp_defaults or require("qmp_defaults")
qmp_network  = qmp_network  or require("qmp_network")
qmp_system   = qmp_system   or require("qmp_system")
qmp_uci      = qmp_uci      or require("qmp_uci")
qmp_wireless = qmp_wireless or require("qmp_wireless")


function configure_hostname()
  local hostname = nil
  if #arg == 2 then
    hostname = arg[2]
  end
  qmp_system.configure_hostname(arg[2])
end

function configure_network()
  -- qmp_configure
  -- qmp_bmx6_reload
  -- /etc/init.d/network reload
  -- if gwck then /etc/init.nd/gwck reload
  -- /etc/init.d/dnsmaq restart
  -- qmp_restart_firewall
end

function configure_wireless()
  qmp_wireless.initial()
  -- qmp_configure_wifi_initial
  -- qmp_configure_wifi
  -- configure_network
  -- /etc/init.d/network reload
  -- if /etc/init.d/gwck enabled
  --   then
  --   /etc/init.d/gwck restart
  -- fi
end

function initialize()
  -- Initialize the configuration file
  qmp_config.initialize()
end

function print_help()
  print("qmpcontrol is a handy script that allows controlling and configuring several")
  print("aspects of this qMp device. Several commands are available, sorted in different")
  print("categories.")
  print("")
  print("Usage: qmpcontrol <command> [options]")
  print("")
  print("Initialization:")
  print(" initialize                        : ")
  print("")
  print("General device configuration:")
  print(" configure_network                 : Configure all the network interfaces according to the settings in /etc/config/qmp")
  print(" configure_wireless                : Configure the wireless interfaces according to the settings in /etc/config/qmp")
  print("")
  print("System configuration:")
  print(" configure_hostname                : Configure the device hostname with the specified name or using the default settings")
  print("Other:")
  print(" help                              : Show this help")
  print("")
end


if #arg < 1 then
  print_help()
  os.exit(1)
end

local command = arg[1]

if command == "configure_network" then
  configure_network()

elseif command == "configure_wireless" or command == "configure_wifi" then
  configure_wireless()

elseif command == "configure_hostname" then
  configure_hostname()

elseif command == "configure_hostname" then
  configure_hostname()

elseif command == "initialize" then
  initialize()

else
  print_help()
end
