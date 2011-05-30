module("luci.controller.bmx6", package.seeall)
 
function index()
       
        -- ToDo: Put this code in a function
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
end
 
function action_status()
        local data = get_bmx_data("interfaces")
        if data == nil then return nil end
        luci.template.render("bmx6/status", {data=data.interfaces})
end
 
 
function action_interfaces()
        local data = get_bmx_data("interfaces")
        if data == nil then return nil end
        luci.template.render("bmx6/interfaces", {data=data.interfaces})
end
 
function action_neighbours()
        local data = get_bmx_data("neighbours")
        if data == nil then return nil end
        luci.template.render("bmx6/neighbours", {data=data.neighbours})
end
 
function action_wireless()
        local data = get_bmx_data("wireless")
        if data == nil then return nil end
        luci.template.render("bmx6/wireless", {data=data.interfaces})
end

----------------
--   Private
---------------- 

-- Returns a LUA object from bmx6 JSON daemon
function get_bmx_data(field)
        require("luci.ltn12")
        require("luci.json")
        local uci = require "luci.model.uci"
        local url = uci.cursor():get("luci-bmx6","luci","json")
 
        if url == nil then
                print_error("bmx6 json url not configured, cannot fetch bmx6 daemon data")
                return nil
                end
 
        local raw = luci.sys.httpget(url..field)
        local data = nil
       
        if raw:len() > 10 then
                local decoder = luci.json.Decoder()
                luci.ltn12.pump.all(luci.ltn12.source.string(raw), decoder:sink())
                data = decoder:get()
        else
                print_error("Cannot get data from bmx6 daemon")
                return nil     
        end
 
        return data
end    
 
function print_error(txt)
        luci.util.perror(txt)
        luci.template.render("bmx6/error", {txt=txt})
end

