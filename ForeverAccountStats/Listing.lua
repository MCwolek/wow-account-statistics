-- Pure text for the /stats chat output: the Tracked Characters listing and the per-Statistic dump.
local _, ns = ...
local L = ns.L

local Listing = {}
ns.Listing = Listing

local MINUTE, HOUR, DAY = 60, 3600, 86400

-- Relative Last Synced, such as "5 d ago", or "now" under a minute.
function Listing.relativeLastSynced(syncedAt, now)
  local elapsed = now - syncedAt
  if elapsed >= DAY then
    return string.format(L.DAYS_AGO, math.floor(elapsed / DAY))
  elseif elapsed >= HOUR then
    return string.format(L.HOURS_AGO, math.floor(elapsed / HOUR))
  elseif elapsed >= MINUTE then
    return string.format(L.MINUTES_AGO, math.floor(elapsed / MINUTE))
  end
  return L.NOW
end

-- Name of a Tracked Character in the listing: Full Name plus Ruleset, since a Full Name repeats across Rulesets.
-- Characters synced before Rulesets were saved have none until their next Sync.
local function displayName(character)
  if character.ruleset == nil then
    return character.fullName
  end
  return string.format(L.CHARACTER_WITH_RULESET, character.fullName, character.ruleset)
end

-- Chat lines for /stats: a header, then each Tracked Character by Full Name and Ruleset with its Last Synced.
-- The logged-in Character (`currentGUID`) reads "now": it Synced on login and Syncs again on logout.
function Listing.lines(db, currentGUID, now)
  local entries = {}
  for guid, character in pairs(db.characters) do
    local synced = guid == currentGUID and L.NOW or Listing.relativeLastSynced(character.lastSynced, now)
    entries[#entries + 1] = { name = displayName(character), synced = synced }
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

-- What the /stats arguments ask for: { action = "list" }, { action = "dump", statisticID = n } or
-- { action = "usage" } for anything else.
function Listing.parseCommand(message)
  local words = {}
  for word in message:lower():gmatch("%S+") do
    words[#words + 1] = word
  end
  if #words == 0 then
    return { action = "list" }
  end
  local statisticID = words[1] == "dump" and #words == 2 and tonumber(words[2]:match("^%d+$"))
  if statisticID then
    return { action = "dump", statisticID = statisticID }
  end
  return { action = "usage" }
end

-- Chat lines for /stats dump: the Statistic's name and ID, each Tracked Character's value as stored in its
-- Snapshot, then the Account Total. `statisticName` is nil when the game knows no such Statistic.
function Listing.statisticLines(db, statisticID, statisticName)
  local entries, snapshots = {}, {}
  for _, character in pairs(db.characters) do
    local snapshot = character.snapshot or {}
    snapshots[#snapshots + 1] = snapshot
    entries[#entries + 1] = { name = displayName(character), value = ns.Values.display(snapshot[statisticID]) }
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
