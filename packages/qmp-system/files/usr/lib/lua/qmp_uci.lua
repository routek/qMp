#!/usr/bin/lua

local uci = require ("uci")

local OWRT_CONFIG_DIR = "/etc/config/"

local qmp_uci = {}

local set_option_typenamesec

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



-- Get the value of an option in a named section of a certain type in a configuration file
local function get_option_namesec(filename, secname, opname)
  local cursor = uci.cursor()
  return cursor:get(filename, secname, opname)
end



-- Get the value of an option in an unnamed section of a certain type -identified
-- by its index- in a configuration file
local function get_option_nonamesec(filename, sectype, secindex, opname)

  local opvalue = {}

  -- Add some logic to ensure the index is valid or assume it is 0
  if type(secindex) ~= "number" then
    if tonumber(secindex) >= 0 then
      secindex = tonumber(secindex)
    else
      secindex = 0
    end
  end

  if filename ~= nil and sectype ~= nil and opname ~= nil and opvalue ~= nil then
    local cursor = uci.cursor()

    local secname = nil

    -- Run through all the sections of the specified type
    cursor:foreach(filename, sectype, function (s)

      -- Find the section specified with the index
      if s[".index"] == secindex then
        opvalue = s[opname]
      end
    end)
end

  return (opvalue)
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



-- Set an option -> value pair to a named section in a configuration file
local function set_option_namesec(filename, secname, opname, opvalue)
  if filename ~= nil and secname ~= nil and opname ~= nil and opvalue ~= nil then
    local cursor = uci.cursor()
    cursor:set(filename, secname, opname, opvalue)
    cursor:save(filename)
    cursor:commit(filename)
  end
end



-- Set an option -> value pair to an unnamed section of a certain type -identified
-- by its index- in a configuration file
local function set_option_nonamesec(filename, sectype, secindex, opname, opvalue)

  -- Add some logic to ensure the index is valid or assume it is 0
  if type(secindex) ~= "number" then
    if tonumber(secindex) >= 0 then
      secindex = tonumber(secindex)
    else
      secindex = 0
    end
  end

  if filename ~= nil and sectype ~= nil and opname ~= nil and opvalue ~= nil then
    local cursor = uci.cursor()

    local secname = nil

    -- Run through all the sections of the specified type
    cursor:foreach(filename, sectype, function (s)

      -- Get the name of the section specified with the index
      if s[".index"] == secindex then
        secname = s[".name"]
      end
    end)

    -- If the section was found, set the name=>value pair
    if secname ~= nil then
      cursor:set(filename, secname, opname, opvalue)
    end
    cursor:save(filename)
    cursor:commit(filename)
  end
end


-- Set an option -> value pair to a named section of a certain type in a configuration file
local function set_option_typenamesec(filename, sectype, secname, opname, opvalue)

  if filename ~= nil and sectype ~= nil and secname ~= nil and opname ~= nil and opvalue ~= nil then

    local cursor = uci.cursor()
    local secfound = false

    -- Run through all the sections of the specified type
    cursor:foreach(filename, sectype, function (s)

      -- Get the name of the section specified with the index
      if s[".name"] == secname and s[".type"] == sectype then
        secfound = true
      end
    end)

    -- If the section was found, set the name=>value pair
    if secfound then
      cursor:set(filename, secname, opname, opvalue)
    end
    cursor:save(filename)
    cursor:commit(filename)
  end
end



qmp_uci.config_file_exists = config_file_exists
qmp_uci.get_option_namesec = get_option_namesec
qmp_uci.get_option_nonamesec = get_option_nonamesec
qmp_uci.isset_option_secname = isset_option_secname
qmp_uci.new_section_typename = new_section_typename
qmp_uci.sectypename_in_file = sectypename_in_file
qmp_uci.set_option_namesec = set_option_namesec
qmp_uci.set_option_typenamesec = set_option_typenamesec
qmp_uci.set_option_nonamesec = set_option_nonamesec


return qmp_uci
