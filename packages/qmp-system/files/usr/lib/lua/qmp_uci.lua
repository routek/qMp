#!/usr/bin/lua

local uci = require ("uci")

local OWRT_CONFIG_DIR = "/etc/config/"

local qmp_uci = {}

-- Check if a config file exists
local function config_file_exists(filename)
  if filename ~= nil then
    print("Filename: "..filename)
  end

end


-- Create an empty section of a certain type and name in a configuration file
-- or do nothing if it already exists
local function new_section_typename(filename, sectype, secname)
  if filename ~= nil and sectype  ~= nil and secname ~= nil then
    local cursor = uci.cursor()
    cursor:set(filename, secname, sectype)
    cursor:save(filename)
    cursor:commit(filename)
  end
end



-- Check if an option is set in a section of a certain name in a configuration file
local function isset_option_secname(filename, secname, opname)
  if filename ~= nil and secname ~= nil and opname ~= nil then
    local cursor = uci.cursor()
    if cursor:get(filename, secname, opname) ~= nil then
      return true
    end
  end

  return false
end




-- Check if a section of a certain type and name exists in a configuration file
local function sectypename_in_file(filename, sectype, secname)
  local exists = false

  if filename ~= nil and sectype ~= nil and secname ~= nil then
    local cursor = uci.cursor()
    cursor:foreach(filename, sectype, function(s)
      if s[".name"] == secname then
        exists = true
        return
      end
    end)
  end

  return exists
end

-- Set an option -> value pair to a section of a certain type and name in a
-- configuration file
local function set_option(filename, secname, opname, opvalue)
  if filename ~= nil and secname ~= nil and opname ~= nil and opvalue ~= nil then
    local cursor = uci.cursor()
    cursor:set(filename, secname, opname, opvalue)
    cursor:save(filename)
    cursor:commit(filename)
  end
end

qmp_uci.config_file_exists = config_file_exists
qmp_uci.isset_option_secname = isset_option_secname
qmp_uci.new_section_typename = new_section_typename
qmp_uci.sectypename_in_file = sectypename_in_file
qmp_uci.set_option = set_option

return qmp_uci