#!/usr/bin/lua

local nixiofs = require("nixio.fs")

local qmp_io = qmp_io or {}

-- Local functions declaration
local is_file
local ls
local new_file
local read_file


-- Check if a file exists
function is_file (filename)
  return nixiofs.stat(filename, 'type') == 'reg'
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


-- Create a new (empty) file
function new_file (filename)
  nixiofs.writefile(filename, '')
  return is_file(filename)
end


-- Read a file and return its content, line per line, in a table
function read_file (filename)
  -- Check if the file exists
  if is_file(filename) then
    local lines = {}

    for line in io.lines(filename) do
      table.insert(lines, line)
    end

    return lines
  end
  return
end


qmp_io.is_file = is_file
qmp_io.ls = ls
qmp_io.new_file = new_file
qmp_io.read_file = read_file


return qmp_io
