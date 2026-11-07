-- Pure text for the /fas listing of Tracked Characters.
local _, ns = ...
local L = ns.L

local Listing = {}
ns.Listing = Listing

local MINUTE, HOUR, DAY = 60, 3600, 86400

-- Relative Last Synced, such as "5 d ago", or "now" under a minute.
function Listing.lastSynced(lastSynced, now)
  local elapsed = now - lastSynced
  if elapsed >= DAY then
    return string.format(L.DAYS_AGO, math.floor(elapsed / DAY))
  elseif elapsed >= HOUR then
    return string.format(L.HOURS_AGO, math.floor(elapsed / HOUR))
  elseif elapsed >= MINUTE then
    return string.format(L.MINUTES_AGO, math.floor(elapsed / MINUTE))
  end
  return L.NOW
end

-- Chat lines for /fas: a header, then each Tracked Character by Full Name with its Last Synced.
-- The logged-in Character (`currentGUID`) reads "now": it Synced on login and Syncs again on logout.
function Listing.lines(db, currentGUID, now)
  local entries = {}
  for guid, character in pairs(db.characters) do
    local synced = guid == currentGUID and L.NOW or Listing.lastSynced(character.lastSynced, now)
    entries[#entries + 1] = { fullName = character.fullName, synced = synced }
  end
  table.sort(entries, function(a, b)
    return a.fullName < b.fullName
  end)

  local lines = { string.format(L.TRACKED_CHARACTERS_HEADER, #entries) }
  for _, entry in ipairs(entries) do
    lines[#lines + 1] = string.format(L.TRACKED_CHARACTER_LINE, entry.fullName, entry.synced)
  end
  return lines
end
