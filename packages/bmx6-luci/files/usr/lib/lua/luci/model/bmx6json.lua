local ltn12 = require("luci.ltn12")
local json = require("luci.json")
local util = require("luci.util")
local uci = require("luci.model.uci")
local sys = require("luci.sys")
local template = require("luci.template")
local http = require("luci.http")
local string = require "string"

module "luci.model.bmx6json"

-- Returns a LUA object from bmx6 JSON daemon

function get(field)
	local url = uci.cursor():get("luci-bmx6","luci","json")

	if url == nil then
		 print_error("bmx6 json url not configured, cannot fetch bmx6 daemon data",true)
		 return nil
	 end

	 local json_url = util.split(url,":")
	 local raw = ""

	if json_url[1] == "http"  then
		raw = sys.httpget(url..field)
	else 

		if json_url[1] == "exec" then
			raw = sys.exec(json_url[2]..' '..field)
		else
			print_error("bmx6 json url not recognized, cannot fetch bmx6 daemon data. Use http: or exec:",true)
			return nil
		end

	end

	local data = nil

	if raw:len() > 10 then
		local decoder = json.Decoder()
		ltn12.pump.all(ltn12.source.string(raw), decoder:sink())
		data = decoder:get()
	else
		print_error("Cannot get data from bmx6 daemon",true)
		return nil     
	end

	return data
end    

function print_error(txt,popup)
	util.perror(txt)
	sys.call("logger -t bmx6json " .. txt)

	if popup then
		http.write('<script type="text/javascript">alert("Some error detected, please check it: '..txt..'");</script>')
	else
		http.write("<h1>Dammit! some error detected</h1>")
		http.write("bmx6-luci: " .. txt)
		http.write('<p><FORM><INPUT TYPE="BUTTON" VALUE="Go Back" ONCLICK="history.go(-1)"></FORM></p>')
	end

end

function text2html(txt)
	txt = string.gsub(txt,"<","{")
	txt = string.gsub(txt,">","}")
	txt = util.striptags(txt)
	return txt
end

