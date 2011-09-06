local sys = require("luci.sys")
local bmx6json = require("luci.model.bmx6json")

m = Map("bmx6", "bmx6")

-- Getting json and Checking if bmx6-json is avaiable
local options = bmx6json.get("options")
if options == nil or options.OPTIONS == nil then
	 m.message = "bmx6-json plugin is not running or some mistake in luci-bmx6 configuration, check /etc/config/luci-bmx6"
else
	options = options.OPTIONS
end

-- Getting a list of interfaces
local eth_int = luci.sys.net.devices()

-- Getting the most important options from general
local general = m:section(NamedSection,"general","general","General")
general.addremove = false
general:option(Value,"globalPrefix","Global ip prefix","Specify global prefix for interfaces: NETADDR/LENGTH")

if m:get("ipVersion","ipVersion") == "6" then
	general:option(Value,"niitSource","Ipv4 niit source","Specify niit4to6 source IP address (IP MUST be assigned to niit4to6 interface!)")
end

-- IP section
-- ipVersion section is important, we are allways showing it
local ipV = m:section(NamedSection,"ipVersion","ipVersion","IP options")
ipV.addremove = false
local lipv = ipV:option(ListValue,"ipVersion","IP version")
lipv:value("4","4")
lipv:value("6","6")
lipv.default = "6"

-- rest of ip options are optional, getting them from json
local ipoptions = {}
for _,o in ipairs(options) do
	if o.name == "ipVersion" and o.CHILD_OPTIONS ~= nil then
		ipoptions = o.CHILD_OPTIONS
		break
	end
end 

local help = ""
local name = ""
local value = nil

for _,o in ipairs(ipoptions) do
	if o.name ~= nil then
		help = ""
		name = o.name
		if o.help ~= nil then
			help = bmx6json.text2html(o.help)
		end

		if o.syntax ~= nil then
			help = help .. "<br/><strong>Syntax: </strong>" .. bmx6json.text2html(o.syntax)
		end

		if o.def ~= nil then
			help = help .. "<br/><strong> Default: </strong>" .. bmx6json.text2html(o.def)
		end

		value = ipV:option(Value,name,name,help)
		value.optional = true
	end
end

-- Interfaces section
local interfaces = m:section(TypedSection,"dev","Devices","")
interfaces.addremove = true
interfaces.anonymous = false
local intlv = interfaces:option(ListValue,"dev","Device")

for _,i in ipairs(eth_int) do
	intlv:value(i,i)
end

function m.on_commit(self,map)
    local err = sys.call('bmx6 -c --configReload > /tmp/bmx6-luci.err.tmp')
    if err ~= 0 then
        m.message = sys.exec("cat /tmp/bmx6-luci.err.tmp")
    end
end

return m

