#!/usr/bin/lua

local nixiofs = require("nixio.fs")

local qmp_io = {}

-- Local functions declaration
local ls
local is_file



-- Check if a file exists
function is_file (filename)
  return nixiofs.stat(filename, 'type') == 'reg'
end



-- Create a new (empty) file
function new_file (filename)
  nixiofs.writefile(filename, '')
  return is_file(filename)
end


-- List a directory
function ls (dirname)

  local dircontent = {}

  local i, t, popen = 0, {}, io.popen

  for filename in popen('ls "'..dirname..'"'):lines() do
    table.insert(dircontent, filename)
  end

  return dircontent

end





qmp_io.is_file = is_file
qmp_io.new_file = new_file
qmp_io.ls = ls


return qmp_io