#!/usr/bin/lua

local uci = require ("uci")

local OWRT_CONFIG_DIR = "/etc/config/"

local qmp_uci = qmp_uci or {}

local set_option_typenamesec

-- Check if a config file exists
local function config_file_exists(filename)
  if filename ~= nil then
    print("Filename: "..filename)
  end

end


-- Count the number of sections of a certain type in a configuration file
local function count_typesec(filename, sectype)

  if filename ~= nil and sectype ~= nil then

    local cursor = uci.cursor()
    local secfound = 0

    -- Run through all the sections of the specified type
    cursor:foreach(filename, sectype, function (s)
      secfound = secfound +1
    end)

    return (secfound)
  end
end


-- Delete a section of a certain name in a configuration file
local function delete_namesec(filename, secname)

  if filename ~= nil and secname ~= nil then
    local cursor = uci.cursor()
    cursor:delete(filename, secname)
    cursor:save(filename)
    cursor:commit(filename)
  end
end


-- Delete all sections of a certain type containing an option of a certain name and value
-- (e.g. in /etc/config/wireless, all wifi-iface sections containing a device radio0)
local function delete_typesecs_by_option_value(filename, sectype, opname, opvalue)

  if filename ~= nil and sectype ~= nil and opname ~= nil and opvalue ~= nil then
    local delsecs = {}
    local cursor = uci.cursor()
    cursor:foreach(filename, sectype, function(s)
      if s[opname] ~= nil and s[opname] == opvalue then
        table.insert(delsecs, s[".name"])
      end
    end)
    for k, v in pairs (delsecs) do
      cursor:delete(filename, v)
    end
    cursor:save(filename)
    cursor:commit(filename)
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


-- Get a section specified by its type and name from a configuration file
local function get_section_by_type_name(filename, sectype, secname)

  local result = {}

  if filename ~= nil and sectype ~= nil and secname ~= nil then
    local cursor = uci.cursor()

    -- Run through all the sections of the specified type
    cursor:foreach(filename, sectype, function (s)
      -- Find the section specified by name
      if s[".name"] == secname then
        result = s
      end
    end)
  end
  return (result)
end


-- Get the names of all typed section that contain an option of a certain name and value
-- (e.g. in /etc/config/wireless, all wifi-iface sections containing a device radio0)
local function get_secnames_by_type_option_value(filename, sectype, opname, opvalue)

  if filename ~= nil and sectype ~= nil and opname ~= nil and opvalue ~= nil then
    local namesecs = {}
    local cursor = uci.cursor()
    cursor:foreach(filename, sectype, function(s)
      if s[opname] ~= nil and s[opname] == opvalue then
        table.insert(namesecs, s[".name"])
      end
    end)
    return (namesecs)
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
qmp_uci.count_typesec = count_typesec
qmp_uci.delete_namesec = delete_namesec
qmp_uci.delete_typesecs_by_option_value = delete_typesecs_by_option_value
qmp_uci.get_option_namesec = get_option_namesec
qmp_uci.get_option_nonamesec = get_option_nonamesec
qmp_uci.get_secnames_by_type_option_value = get_secnames_by_type_option_value
qmp_uci.get_section_by_type_name = get_section_by_type_name
qmp_uci.isset_option_secname = isset_option_secname
qmp_uci.new_section_typename = new_section_typename
qmp_uci.sectypename_in_file = sectypename_in_file
qmp_uci.set_option_namesec = set_option_namesec
qmp_uci.set_option_typenamesec = set_option_typenamesec
qmp_uci.set_option_nonamesec = set_option_nonamesec


return qmp_uci
