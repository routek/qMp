m = Map("bmx6", "bmx6")

local bmx6json = require("luci.model.bmx6json")
local util = require("luci.util")
local http = require("luci.http")
local sys = require("luci.sys")

local options = bmx6json.get("options")
if options == nil or options.OPTIONS == nil then 
	m.message = "bmx6-json plugin is not running or some mistake in luci-bmx6 configuration, check /etc/config/luci-bmx6"  
	options = {}
else
	options = options.OPTIONS
end

local general = m:section(NamedSection,"general","general","General Options")

local name = ""
local help = ""
local value = nil

for _,o in ipairs(options) do 
	if o.name ~= nil and o.CHILD_OPTIONS == nil then
		help = ""
		name = o.name

		if o.help ~= nil then 
			help = bmx6json.text2html(o.help) 
		end

		if o.syntax ~= nil then 
			help = help .. "<br/><strong>Syntax: </strong>" .. bmx6json.text2html(o.syntax) 
		end

		if o.def ~= nil then
			help = help .. "<strong> Default: </strong>" .. o.def
		end

		value = general:option(Value,name,name,help)

	end
end

function m.on_commit(self,map)
	local err = sys.call('bmx6 -c --configReload > /tmp/bmx6-luci.err.tmp')
	if err ~= 0 then
		m.message = sys.exec("cat /tmp/bmx6-luci.err.tmp")
	end
end

return m

