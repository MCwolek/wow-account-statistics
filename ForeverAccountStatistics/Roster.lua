-- Pure Roster of Tracked Characters: the one place that names them by Full Name and Ruleset, orders them and resolves
-- their Last Synced.
-- The Character dropdown, /stats list, /stats dump and the Breakdown all take Tracked Characters from it.
local _, ns = ...
local L = ns.L

local Roster = {}
ns.Roster = Roster

local MINUTE, HOUR, DAY = 60, 3600, 86400

-- Label of a Tracked Character: Full Name plus Ruleset, since a Full Name repeats across Rulesets.
-- Characters synced before Rulesets were saved have none until their next Sync.
local function labelOf(character)
  if character.ruleset == nil then
    return character.fullName
  end
  return string.format(L.CHARACTER_WITH_RULESET, character.fullName, character.ruleset)
end

-- Last Synced `syncedAt` relative to `now`, such as "5 d ago", or "now" under a minute.
local function relativeLastSynced(syncedAt, now)
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

-- The Roster of the Tracked Characters in `db`, the SavedVariables, at the time `now`, in order of Full Name and
-- Ruleset. Each entry:
--   guid, class
--   faction: "Horde" or "Alliance", or nil until a Character tracked before Factions were recorded Syncs again
--   label: Full Name and Ruleset
--   isCurrent: whether it is the logged-in Character, `currentGUID`
--   lastSynced: its Last Synced; `now` for the logged-in Character, which Synced on login, Syncs again on logout and
--     whose values the Statistics window reads live
--   relativeLastSynced: lastSynced relative to `now`, such as "5 d ago" or "now"
function Roster.of(db, currentGUID, now)
  local roster = {}
  for guid, character in pairs(db.characters) do
    local isCurrent = guid == currentGUID
    local lastSynced = isCurrent and now or character.lastSynced
    roster[#roster + 1] = {
      guid = guid,
      label = labelOf(character),
      class = character.class,
      faction = character.faction,
      isCurrent = isCurrent,
      lastSynced = lastSynced,
      relativeLastSynced = relativeLastSynced(lastSynced, now),
    }
  end
  table.sort(roster, function(a, b)
    return a.label < b.label
  end)
  return roster
end
