-- Helpers for loading add-on files the way the WoW client does.
local M = {}

M.DIR = "AccountStatistics"

-- Locale.lua asks the game for its text language at load; the specs play an English client.
---@diagnostic disable-next-line: duplicate-set-field
_G.GetLocale = function()
  return "enUS"
end

-- Runs one add-on file with the (addonName, namespace) varargs the client passes.
function M.loadFile(path, ns)
  local chunk = assert(loadfile(M.DIR .. "/" .. path))
  chunk(M.DIR, ns)
  return ns
end

-- Returns the .toc metadata ("## Key: value") and the ordered list of files it loads.
function M.readToc()
  local metadata, files = {}, {}
  for line in io.lines(M.DIR .. "/" .. M.DIR .. ".toc") do
    local key, value = line:match("^##%s*([^:]+):%s*(.-)%s*$")
    if key then
      metadata[key] = value
    elseif line:match("%S") and not line:match("^#") then
      files[#files + 1] = line:match("^%s*(.-)%s*$")
    end
  end
  return metadata, files
end

return M
