local sys = require("luci.sys")
local bmx6json = require("luci.model.bmx6json")
local m = Map("bmx6", "bmx6")

local eth_int = sys.net.devices()
local interfaces = m:section(TypedSection,"dev","Devices","")
interfaces.addremove = true
interfaces.anonymous = true

local intlv = interfaces:option(ListValue,"dev","Device")

for _,i in ipairs(eth_int) do
	intlv:value(i,i)
end

-- Getting json and looking for device section
local json = bmx6json.get("options")

if json == nil or json.OPTIONS == nil then 
	m.message = "bmx6-json plugin is not running or some mistake in luci-bmx6 configuration, check /etc/config/luci-bmx6"
	json = {}
else
	json = json.OPTIONS
end

local dev = {}
for _,j in ipairs(json) do
	if j.name == "dev" and j.CHILD_OPTIONS ~= nil then
		dev = j.CHILD_OPTIONS
		break
	end
end

local help = ""
local name = ""

for _,o in ipairs(dev) do
	if o.name ~= nil then
		help = ""
		name = o.name
		if o.help ~= nil then
			help = bmx6json.text2html(o.help)
		end

		if o.syntax ~= nil then
			help = help .. "<br/><strong>Syntax: </strong>" .. bmx6json.text2html(o.syntax)
		end

		value = interfaces:option(Value,name,name,help)
		value.optional = true
	end
end


return m

