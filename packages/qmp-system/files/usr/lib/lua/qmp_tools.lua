#!/usr/bin/lua


-- Local functions declaration
local array_to_list
local array_unique
local is_item_in_array
local list_to_array
local remove_item_from_array
local times_item_in_array


local qmp_tools = {}


function array_to_list(arr)

  local list = ""

  if type(arr) == "table" then
    for k, v in pairs (arr) do
      if list ~= "" then
        list = list .. " "
      end
      list = list .. v
    end
  end

  return list
end



function array_unique(arr)

  local uarr = {}

  if type(arr) == "table" then
    for k, v in pairs (arr) do
      local added = false
      for l, w in pairs(uarr) do
        if v == w then
          added = true
        end
      end
      if not added then
        table.insert(uarr,v)
      end
    end
    return uarr
  end

  return arr
end



function is_item_in_array(item, list)

  local times = times_item_in_array(item, list)

  if type(times) == "number" then
    if times == 0 then
      return false
    else
      return true
    end
  end

  return nil
end


function list_to_array(list)

  local arrlist = {}

  if type(list) == "string" then
    for i in string.gmatch(list, "%S+") do
      table.insert(arrlist, i)
    end
  end

  return arrlist
end


function remove_item_from_array(item, array)

  local rarray = {}

  if type(item) == "string" and type(array) == "table" then
    for k, v in pairs(array) do
      if v ~= item then
        table.insert(rarray, v)
      end
    end
    return rarray
  end

  return array
end



function times_item_in_array(item, list)

  local times = nil

  if type(item) == "string" and type(list) == "table" then
    times = 0
    for k, v in pairs(list) do
      if v == item then
        times = times + 1
      end
    end
  end

  return times
end



qmp_tools.array_to_list = array_to_list
qmp_tools.is_item_in_array = is_item_in_array
qmp_tools.list_to_array = list_to_array
qmp_tools.remove_item_from_array = remove_item_from_array
qmp_tools.times_item_in_array = times_item_in_array
qmp_tools.array_unique = array_unique

return qmp_tools
