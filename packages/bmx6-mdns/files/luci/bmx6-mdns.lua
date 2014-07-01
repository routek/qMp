--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008-2013 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local fs = require "nixio.fs"
local globalfile = "/etc/mdns/public" 
local dom4file = "/etc/mdns/domain4"
local dom6file = "/etc/mdns/domain6"
local hostfile = "/etc/mdns/hosts"

f = SimpleForm("mesh-dns", translate("Mesh DNS"), translate( "Distributed DNS system using the bmx6 packets to encode domains."))

d4 = f:field(Value, "dom4", translate("IPv4 domain extension"), translate("Only IPv4 domains with this extension will be considered valid"))
d4.rmempty = false
function d4.cfgvalue()
	return fs.readfile(dom4file) or ""
end

d6 = f:field(Value, "dom6", translate("IPv6 domain extension"), translate("Only IPv6 domains with this extension will be considered valid"))
d6.rmempty = false
function d6.cfgvalue()
	return fs.readfile(dom6file) or ""
end

t = f:field(TextValue, "mdns", translate("Domains to publish"), translate("Syntax: IP@domain<br/>Examples:\
<pre>proxy1.qmp@10.1.2.3<br/>proxy1.qm6@fd00:1714:1714:1677:120b::23c1</pre><br/>\
A line with a single domain name is published as own domain with the node's IP."))
t.rmempty = false
t.rows = 20
function t.cfgvalue()
	return fs.readfile(globalfile) or ""
end

function f.handle(self, state, data)
	if state == FORM_VALID then
		if data.mdns then
			fs.writefile(globalfile, data.mdns:gsub("\r\n", "\n"))
			luci.sys.call("/etc/init.d/mdns reload >/dev/null")
		end
		if data.dom4 then
			fs.writefile(dom4file, data.dom4:gsub("\r\n", "\n"))
		end
		if data.dom6 then
			fs.writefile(dom6file, data.dom6:gsub("\r\n", "\n"))
		end
	end
	return true
end

hosts = fs.readfile(hostfile) or ""
h = f:field(DummyValue, "hosts", translate("Current obtained domains"))
h.rawhtml = true
h.default = "<pre>"..hosts.."</pre>"
h.rmempty = false

return f
