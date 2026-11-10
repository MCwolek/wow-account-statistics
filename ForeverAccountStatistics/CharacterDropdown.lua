-- Pure entries of the Statistics window's Character dropdown, taken from the Roster of Tracked Characters (see
-- Roster.of).
local _, ns = ...
local L = ns.L

local CharacterDropdown = {}
ns.CharacterDropdown = CharacterDropdown

-- The dropdown's entries: the Roster's entries with the logged-in Character first, then the others in Roster order.
function CharacterDropdown.entries(roster)
  local current, others = nil, {}
  for _, entry in ipairs(roster) do
    if entry.isCurrent then
      current = entry
    else
      others[#others + 1] = entry
    end
  end
  local entries = { current }
  for _, entry in ipairs(others) do
    entries[#entries + 1] = entry
  end
  return entries
end

-- Tooltip of a dropdown entry: its Last Synced as an exact date and time, through `formatDate` (the game's date()).
function CharacterDropdown.lastSyncedTooltip(entry, formatDate)
  return string.format(L.LAST_SYNC, formatDate(L.EXACT_DATE_TIME, entry.lastSynced))
end
