--[[
    Copyright (C) 2011 Fundació Privada per a la Xarxa Oberta, Lliure i Neutral guifi.net

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

    The full GNU General Public License is included in this distribution in
    the file called "COPYING".
--]]

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

	--- neighbours
	table.insert(place,"Neighbours")
	entry(place,call("action_neighbours"),"Neighbours") 
	table.remove(place)
 
	--- links
	table.insert(place,"Links")
	entry(place,call("action_links"),"Links") 
	table.remove(place)

	--- chat
	table.insert(place,"Chat")
	entry(place,call("action_chat"),"Chat") 
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
		local status = bmx6json.get("status").status or nil
		local interfaces = bmx6json.get("interfaces").interfaces or nil

		if status == nil or interfaces == nil then
			luci.template.render("bmx6/error", {txt="Cannot fetch data from bmx6 json"})	
		else
        	luci.template.render("bmx6/status", {status=status,interfaces=interfaces})
		end
end
 
function action_neighbours()
		local orig_list = bmx6json.get("originators").originators or nil

		if orig_list == nil then
			luci.template.render("bmx6/error", {txt="Cannot fetch data from bmx6 json"})
			return nil
		end

		local originators = {}
		local desc = nil
		local orig = nil
		local name = ""
		
		for _,o in ipairs(orig_list) do
			orig = bmx6json.get("originators/"..o.name) or {}
			desc = bmx6json.get("descriptions/"..o.name) or {}
		
			if string.find(o.name,'.') then
				name = luci.util.split(o.name,'.')[1]
			else
				name = o.name
			end
			
			table.insert(originators,{name=name,orig=orig,desc=desc})
		end

        luci.template.render("bmx6/neighbours", {originators=originators})
end
 
function action_links()
	local links = bmx6json.get("links")
	local devlinks = {}
	
	if links ~= nil then
		links = links.links
		for _,l in ipairs(links) do
			devlinks[l.viaDev] = {}
		end
		for _,l in ipairs(links) do
			table.insert(devlinks[l.viaDev],l)	
		end
	end

	luci.template.render("bmx6/links", {links=devlinks}) 
end

function action_chat()
	local sms_dir = "/var/run/bmx6/sms"
	local rcvd_dir = sms_dir .. "/rcvdSms"
	local send_file = sms_dir .. "/sendSms/chat"
	local sms_list = bmx6json.get("rcvdSms")
	local sender = ""
	local sms_file = ""
	local chat = {}
	local to_send = nil
	local sent = ""
	local fd = nil

	if luci.sys.call("test -d " .. sms_dir) ~= 0 then
		luci.template.render("bmx6/error", {txt="sms plugin disabled or some problem with directory " .. sms_dir})
		return nil
	end

	sms_list = luci.util.split(luci.util.exec("ls "..rcvd_dir.."/*:chat"))

	for _,sms_path in ipairs(sms_list) do
	  if #sms_path > #rcvd_dir then
		sms_file = luci.util.split(sms_path,'/')
		sms_file = sms_file[#sms_file]
		sender = luci.util.split(sms_file,':')[1]

		-- Trying to clean the name
		if string.find(sender,".") ~= nil then
			sender = luci.util.split(sender,".")[1]
		end

		fd = io.open(sms_path,"r")
		chat[sender] = fd:read()
		fd:close()	
	  end
	end

	to_send = luci.http.formvalue("toSend")	
	if to_send ~= nil and #to_send > 1  then
		fd = io.open(send_file,"w")
		fd:write(to_send)
		fd:close()
		sent = to_send
	else
		sent = luci.util.exec("cat "..send_file)
	end

	luci.template.render("bmx6/chat", {chat=chat,sent=sent})
end

