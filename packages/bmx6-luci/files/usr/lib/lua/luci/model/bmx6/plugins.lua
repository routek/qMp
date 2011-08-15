m = Map("bmx6", "bmx6")

plugins_dir = {"/usr/lib/","/var/lib","/lib"}

plugin = m:section(TypedSection,"plugin","Plugin")
plugin.addremove = true
plugin.anonymous = false
plv = plugin:option(ListValue,"plugin", "Plugin") 

for _,d in ipairs(plugins_dir) do
	pl = luci.sys.exec("cd "..d..";ls bmx6_*")
	if #pl > 6 then
		for _,v in ipairs(luci.util.split(pl,"\n")) do
			plv:value(v,v)
		end
	end
end


return m

