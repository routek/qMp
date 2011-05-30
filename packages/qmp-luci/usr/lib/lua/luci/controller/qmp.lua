module("luci.controller.qmp.qmp", package.seeall)

function index()
	entry({"qmp","status"}, call("action:stauts"), "Click here", 10).dependent=false
end
     
function action_status()
	luci.http.prepare_content("text/plain")
	luci.http.write("Quick Mesh Project [qMp]")
end
