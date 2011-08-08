local sys = require("luci.sys")

m = Map("bmx6", "bmx6")

local hna = m:section(TypedSection,"hna","HNA")
hna.addremove = true
hna.anonymous = false
local hna_option = hna:option(Value,"hna", "Host Network Announcement")

function hna_option:validate(value)
	local err = sys.call('bmx6 -c --test -a ' .. value)
	if err ~= 0 then
		return nil
	end	
	return value 
end

return m

