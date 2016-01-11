#!/usr/bin/lua

local qmp_tools = {}

-- List a directory
local function ls (dirname)

  local dircontent = {}

  local i, t, popen = 0, {}, io.popen

  for filename in popen('ls "'..dirname..'"'):lines() do
    table.insert(dircontent, filename)
  end

  return dircontent

end

qmp_tools.ls = ls

return qmp_tools