--[[
    Copyright (C) 2011 Fundacio Privada per a la Xarxa Oberta, Lliure i Neutral guifi.net

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

    The full GNU General Public License is included in this distribution in
    the file called "COPYING".
--]]

require("luci.sys")

m = Map("qmp", "Quick Mesh Project")

ethernet_interfaces = { 'eth', 'ath', 'wlan' }
wireless_interfaces = { 'ath', 'wlan' }

eth_section = m:section(NamedSection, "networks", "qmp", "Interfaces", "Interfaces")
eth_section.addremove = False

-- Option: DNS
eth_section:option(Value, "dns", "Nameservers","Define the nameservers to use")

-- Option: lan addresses
eth_section:option(Value, "lan_address", "LAN address","IPv4 address for LAN interfaces")

-- Option: lan addresses                                          
eth_section:option(Value, "lan_netmask", "LAN netmask","IPv4 netmask for LAN interfaces")

-- Option: olsr6_ripe_prefix48
eth_section:option(Value, "olsr6_ripe_prefix48", "IPv6 prefix for OLSR","IPv6 prefix used for OLSR network")

-- Option: bmx6_ripe_prefix48                 
eth_section:option(Value, "bmx6_ripe_prefix48", "IPv6 prefix for BMX6","IPv6 prefix used for BMX6 network")

-- Option: olsr6_ipv4_prefix24
eth_section:option(Value, "olsr6_ipv4_prefix24", "IPv4 prefix for OLSR","IPv4 prefix used for OLSR network")  

-- Option: bmx6_ipv4_prefix24                                                   
eth_section:option(Value, "bmx6_ipv4_prefix24", "IPv4 prefix for BMX6","IPv4 prefix used for BMX6 network") 

-- Option: netserver
nts = eth_section:option(ListValue, "netserver", "Permit bandwidth test","If enabled the rest of nodes will be able to do bandwidth tests with your node")
nts:value("1","yes")
nts:value("0","no")

-- Option force_internet
fint = eth_section:option(ListValue, "force_internet", "Force internet","Just use it if you want force the system to share/unshare internet")
fint:value("","disabled")
fint:value("1","yes")
fint:value("0","no")


function m.on_commit(self,map)
        luci.sys.call('/etc/qmp/qmp_control.sh apply_network > /tmp/qmp_control_network.log &')
end


return m

