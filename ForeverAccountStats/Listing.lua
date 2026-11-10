-- Pure text for the /stats chat output: the Tracked Characters listing and the per-Statistic dump.
local _, ns = ...
local L = ns.L

local Listing = {}
ns.Listing = Listing

local Characters = ns.Characters

-- Chat lines for /stats: a header, then each Tracked Character by Full Name and Ruleset with its Last Synced.
-- The logged-in Character (`currentGUID`) reads "now".
function Listing.lines(db, currentGUID, now)
  local entries = {}
  for guid, character in pairs(db.characters) do
    entries[#entries + 1] = {
      name = Characters.displayName(character),
      synced = Characters.relativeLastSyncedOf(guid, character, currentGUID, now),
    }
  end
  table.sort(entries, function(a, b)
    return a.name < b.name
  end)

  local lines = { string.format(L.TRACKED_CHARACTERS_HEADER, L.ADDON_TITLE, #entries) }
  for _, entry in ipairs(entries) do
    lines[#lines + 1] = string.format(L.TRACKED_CHARACTER_LINE, entry.name, entry.synced)
  end
  return lines
end

-- Chat lines for /stats dump: the Statistic's name and ID, each Tracked Character's value, then the Account Total.
-- The dump passes AccountStatistics no Live Values, so every value is the one saved in its Snapshot, the logged-in
-- Character's too: the dump reports what the add-on has saved. `statisticName` is nil when the game knows no such
-- Statistic.
function Listing.statisticLines(db, statisticID, statisticName)
  local statistics = ns.AccountStatistics.new(db)
  local lines = {
    string.format(L.STATISTIC_HEADER, L.ADDON_TITLE, statisticName or L.UNKNOWN_STATISTIC, statisticID),
  }
  for _, character in ipairs(statistics:characterValues(statisticID)) do
    lines[#lines + 1] = string.format(L.STATISTIC_LINE, character.label, character.value)
  end
  lines[#lines + 1] = string.format(L.ACCOUNT_TOTAL_LINE, statistics:accountTotal(statisticID))
  return lines
end
