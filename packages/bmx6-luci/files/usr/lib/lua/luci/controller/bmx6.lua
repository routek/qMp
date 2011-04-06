module("luci.controller.bmx6", package.seeall)

function index()
	
	-- ToDo: Put this code in a function
	local place = {}
	local ucim = require "luci.model.uci"
	local uci = ucim.cursor()

	-- checking if ignore is on
	if uci.cursor():get("bmx6","luci","ignore") == "1" then
		return nil
	end

	-- getting value from uci database
	local l1 = uci:get("bmx6","luci","level1")
	local l2 = uci:get("bmx6","luci","level2")
	local l3 = uci:get("bmx6","luci","level3")

	-- default values
	if l1 == nil then main = "bmx6" end
	table.insert(place,l1)

	-- level2 and level3 are optional
	if l2 ~= nil then table.insert(place,l2) end
	if l3 ~= nil then table.insert(place,l3) end
	
	---------------------------
	-- Starting with the pages
	---------------------------
	local page = nil
	
	--- status (this is default one)
	if #place == 1 then
		page = node(place[1])
		page.title = place[1]
	elseif #place == 2 then
		page = node(place[1],place[2])
		page.title = place[2]
	else
	 	page = node(place[1],place[2],place[3])
		page.title = place[3]
        end
	page.target = call("action_stat")
        page.subindex = "false"

	--- interfaces
	if #place == 1 then
		page = node(place[1],"interfaces")                                                                                                             
	elseif #place == 2 then
		page = node(place[1],place[2],"interfaces")
	else
		page = node(place[1],place[2],place[3],"interfaces")
	end
        page.target = call("action_int")
        page.title = "Interfaces"
        page.subindex = "true"

	--- neighbours
	if #place == 1 then
		page = node(place[1],"neighbours")
	elseif #place == 2 then
		page = node(place[1],place[2],"neighbours")
	else
		page = node(place[1],place[2],place[3],"neighbours")
	end
        page.target = call("action_nb")
        page.title = "Neighbours"
        page.subindex = "true"
	
	--- wireless links
	if #place == 1 then
		page = node(place[1],"links")
	elseif #place == 2 then
		page = node(place[1],place[2],"links")
	else
		page = node(place[1],place[2],place[3],"links")
        end
	page.target = call("action_wl")
        page.title = "Wireless Links"
        page.subindex = "true"

end

function action_stat()
	local data = get_bmx_data("interfaces")
	if data == nil then return nil end
	luci.template.render("bmx6/status", {data=data.interfaces})
end


function action_int()
	local data = get_bmx_data("interfaces")
	if data == nil then return nil end
	luci.template.render("bmx6/interfaces", {data=data.interfaces})
end

function action_nb()
	local data = get_bmx_data("neighbours")
	if data == nil then return nil end
	luci.template.render("bmx6/neighbours", {data=data.neighbours})
end

function action_wl()
 	local data = get_bmx_data("wireless")
	if data == nil then return nil end
        luci.template.render("bmx6/wireless", {data=data.interfaces})
end

-- Private 

-- Returns a LUA object from bmx6 JSON daemon
function get_bmx_data(field)
	require("luci.ltn12")
	require("luci.json")
	local uci = require "luci.model.uci"
	local url = uci.cursor():get("bmx6","luci","json")

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


