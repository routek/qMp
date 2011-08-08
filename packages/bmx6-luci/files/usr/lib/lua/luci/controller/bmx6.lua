local bmx6json = require("luci.model.bmx6json")

module("luci.controller.bmx6", package.seeall)
 
function index()
       
	local ucim = require "luci.model.uci"
	local uci = ucim.cursor()
 	local place = {}
	-- checking if ignore is on
	if uci:get("luci-bmx6","luci","ignore") == "1" then
		return nil
	end
	
	-- getting value from uci database
	local uci_place = uci:get("luci-bmx6","luci","place")
	
	-- default values
	if uci_place == nil then 
		place = {"bmx6"} 
	else 
		local util = require "luci.util"
		place = util.split(uci_place," ")
	end
	---------------------------
	-- Starting with the pages
	---------------------------
   
	--- status (this is default one)
	entry(place,call("action_status"),place[#place])	

	--- interfaces
	table.insert(place,"Interfaces")
	entry(place,call("action_interfaces"),"Interfaces") 
	table.remove(place)
 
	--- neighbours
	table.insert(place,"Neighbours")
	entry(place,call("action_neighbours"),"Neighbours") 
	table.remove(place)
 
	--- wireless links
	table.insert(place,"Wireless")
	entry(place,call("action_wireless"),"Wireless") 
	table.remove(place)

	--- configuration (CBI)
	table.insert(place,"Configuration")
	entry(place, cbi("bmx6/main"), "Configuration").dependent=false

	table.insert(place,"Advanced")	
	entry(place, cbi("bmx6/advanced"), "Advanced")
	table.remove(place)
	
	table.insert(place,"Interfaces")	
	entry(place, cbi("bmx6/interfaces"), "Interfaces")
	table.remove(place)

	table.insert(place,"Plugins")	
	entry(place, cbi("bmx6/plugins"), "Plugins")
	table.remove(place)

	table.insert(place,"HNA")	
	entry(place, cbi("bmx6/hna"), "HNA")
	table.remove(place)
	
	table.remove(place)	

end
 
function action_status()
        local data = bmx6json.get("status")
        if data == nil then return nil end
        luci.template.render("bmx6/status", {data=data.status})
end
 
 
function action_interfaces()
        local data = bmx6json.get("interfaces")
        if data == nil then return nil end
        luci.template.render("bmx6/interfaces", {data=data.interfaces})
end
 
function action_neighbours()
        local data = bmx6json.get("neighbours")
        if data == nil then return nil end
        luci.template.render("bmx6/neighbours", {data=data.neighbours})
end
 
function action_wireless()
        local data = bmx6json.get("wireless")
        if data == nil then return nil end
        luci.template.render("bmx6/wireless", {data=data.interfaces})
end

