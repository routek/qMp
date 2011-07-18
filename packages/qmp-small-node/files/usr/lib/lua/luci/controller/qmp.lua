module("luci.controller.qmp.qmp", package.seeall)

function index()
	entry({"qmp"}, call("action_stauts"), "qMp", 1).dependent=false
	entry({"qmp","network"}, cbi("qmp/config"), "Network", 5).dependent=false
	entry({"qmp","wireless"}, cbi("qmp/wireless"), "Wireless", 6).dependent=false
end
     
function action_status()
	luci.http.prepare_content("text/plain")
	luci.http.write("Quick Mesh Project [qMp]")
end
