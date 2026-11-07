-- Pure text for the /stats chat output: the Tracked Characters listing and the per-Statistic dump.
local _, ns = ...
local L = ns.L

local Listing = {}
ns.Listing = Listing

local Characters = ns.Characters

-- Chat lines for /stats: a header, then each Tracked Character by Full Name and Ruleset with its Last Synced.
-- The logged-in Character (`currentGUID`) reads "now": it Synced on login and Syncs again on logout.
function Listing.lines(db, currentGUID, now)
  local entries = {}
  for guid, character in pairs(db.characters) do
    local synced = guid == currentGUID and L.NOW or Characters.relativeLastSynced(character.lastSynced, now)
    entries[#entries + 1] = { name = Characters.displayName(character), synced = synced }
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

-- Chat lines for /stats dump: the Statistic's name and ID, each Tracked Character's value as stored in its
-- Snapshot, then the Account Total. `statisticName` is nil when the game knows no such Statistic.
function Listing.statisticLines(db, statisticID, statisticName)
  local entries, snapshots = {}, {}
  for _, character in pairs(db.characters) do
    local snapshot = character.snapshot or {}
    snapshots[#snapshots + 1] = snapshot
    entries[#entries + 1] = {
      name = Characters.displayName(character),
      value = ns.Values.display(snapshot[statisticID]),
    }
  end
  table.sort(entries, function(a, b)
    return a.name < b.name
  end)

  local lines = {
    string.format(L.STATISTIC_HEADER, L.ADDON_TITLE, statisticName or L.UNKNOWN_STATISTIC, statisticID),
  }
  for _, entry in ipairs(entries) do
    lines[#lines + 1] = string.format(L.STATISTIC_LINE, entry.name, entry.value)
  end
  lines[#lines + 1] = string.format(L.ACCOUNT_TOTAL_LINE, ns.AccountTotals.display(statisticID, snapshots))
  return lines
end
