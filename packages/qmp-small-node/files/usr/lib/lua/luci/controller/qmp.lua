module("luci.controller.qmp", package.seeall)

function index()

	-- Making qmp as default 	
	local root = node()
	root.target = alias("qmp")
	root.index  = true

	-- Main window with auth enabled
	overview = entry({"qmp"}, template("qmp/overview"), "qMp", 1)
	overview.dependent = false
	overview.sysauth = "root"
	overview.sysauth_authenticator = "htmlauth"
	
	-- Rest of entries
	entry({"qmp","network"}, cbi("qmp/config"), "Network", 5).dependent=false
	entry({"qmp","wireless"}, cbi("qmp/wireless"), "Wireless", 6).dependent=false
end
     
function action_status()
	luci.http.prepare_content("text/plain")
	luci.http.write("Quick Mesh Project [qMp]")
end
