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
local http = require "luci.http"
m = Map("qmp", "Quick Mesh Project")

ethernet_interfaces = { 'eth', 'ath', 'wlan' }
wireless_interfaces = { 'ath', 'wlan' }

eth_section = m:section(NamedSection, "networks", "qmp", "Interfaces", "Interfaces")
eth_section.addremove = False

-- Option: DNS
eth_section:option(Value, "dns", "Nameservers",translate("Define the nameservers to use."))

-- Option: lan addresses
eth_section:option(Value, "lan_address", "LAN address",translate("IPv4 address for LAN interfaces."))

-- Option: lan addresses
eth_section:option(Value, "lan_netmask", "LAN netmask",translate("IPv4 netmask for LAN interfaces."))

-- Option: publish lan
--eth_section:option(Flag, "publish_lan", "Publish LAN", "Publish LAN network through the mesh")

-- Option: disable dhcp
eth_section:option(Flag, "disable_lan_dhcp", "Disable DHCP from LAN",
translate("Disable DHCP server in LAN network (not recommended)."))

-- Option bmx6_ipv4_address
eth_section:option(Value, "bmx6_ipv4_address", "Main IPv4 address",
translate("IPv4 address used for bmx6 (main address). Leave blank to randomize."))

-- Option: bmx6_ipv4_prefix24
eth_section:option(Value, "bmx6_ipv4_prefix24", "Random-IPv4 prefix 24",
translate("Used to calculate the IP if it is not defined in the field before (example: 10.40.50)."))

-- Option: bmx6_ripe_prefix48
eth_section:option(Value, "bmx6_ripe_prefix48", "Main IPv6 prefix",
translate("If you have a global IPv6 48bits prefix, specify it here. Otherwise leave it blank."))


-- Option: netserver
nts = eth_section:option(ListValue, "netserver", "Permit bandwidth test",
translate("If enabled all nodes will be able to perform bandwidth tests with your node"))

nts:value("0","no")
nts:value("1","yes")

-- Option force_internet
fint = eth_section:option(ListValue, "force_internet", "Force internet",
translate("Usese it if you want force the system to share/unshare Internet (not recommended)"))
fint:value("","disabled")
fint:value("1","yes")
fint:value("0","no")

----------------------------
-- Non overlapping
---------------------------

overlapping_section = m:section(NamedSection, "roaming", "qmp", 
translate("Roaming", "Layer3 Roaming"))
overlapping_section.addremove = False

ignore = overlapping_section:option(ListValue, "ignore", 
translate("Roaming","If yes, the roaming will be enabled. Each mesh node will give a different /24 to the LAN clients from the same /16."))
ignore:value("1","no")
ignore:value("0","yes")

-- Option: dhcp_offset
overlapping_section:option(Value, "dhcp_offset", "DHCP offset",
translate("Offset to calculate the first IP to give throw DHCP"))

-- Option: Leassetime
overlapping_section:option(Value, "qmp_leasetime", "DHCP leassetime",translate("Leassetime for DHCP"))


--------------------------
-- Commit
-------------------------

function m.on_commit(self,map)
	http.redirect("/luci-static/resources/qmp/wait_long.html")
        luci.sys.call('/etc/qmp/qmp_control.sh configure_all > /tmp/qmp_control_network.log &')
end


return m

