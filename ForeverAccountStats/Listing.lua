-- Pure text for the /stats chat output: the Tracked Characters listing and the per-Statistic dump.
local _, ns = ...
local L = ns.L

local Listing = {}
ns.Listing = Listing

-- Chat lines for /stats: a header, then each Tracked Character of the roster (see Roster.of) by its label, with its
-- relative Last Synced.
function Listing.lines(db, currentGUID, now)
  local roster = ns.Roster.of(db, currentGUID, now)
  local lines = { string.format(L.TRACKED_CHARACTERS_HEADER, L.ADDON_TITLE, #roster) }
  for _, entry in ipairs(roster) do
    lines[#lines + 1] = string.format(L.TRACKED_CHARACTER_LINE, entry.label, entry.relativeLastSynced)
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
