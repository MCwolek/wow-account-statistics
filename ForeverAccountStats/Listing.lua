-- Pure text for the /fas listing of Tracked Characters.
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

-- Chat lines for /fas: a header, then each Tracked Character by Full Name and Ruleset with its Last Synced.
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
