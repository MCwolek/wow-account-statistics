-- Pure presentation of Tracked Characters, shared by the /stats chat output and the Statistics window.
local _, ns = ...
local L = ns.L

local Characters = {}
ns.Characters = Characters

local MINUTE, HOUR, DAY = 60, 3600, 86400

-- Relative Last Synced, such as "5 d ago", or "now" under a minute.
function Characters.relativeLastSynced(syncedAt, now)
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

-- Relative Last Synced of the Tracked Character `guid`, or "now" for the logged-in Character (`currentGUID`): it
-- Synced on login, Syncs again on logout, and the Statistics window reads its values live.
function Characters.relativeLastSyncedOf(guid, character, currentGUID, now)
  if guid == currentGUID then
    return L.NOW
  end
  return Characters.relativeLastSynced(character.lastSynced, now)
end

-- Name of a Tracked Character: Full Name plus Ruleset, since a Full Name repeats across Rulesets.
-- Characters synced before Rulesets were saved have none until their next Sync.
function Characters.displayName(character)
  if character.ruleset == nil then
    return character.fullName
  end
  return string.format(L.CHARACTER_WITH_RULESET, character.fullName, character.ruleset)
end

-- Entries of the window's Character dropdown, { guid, label, class, lastSynced, relative, isCurrent }: the
-- logged-in Character (`currentGUID`) first, reading "now" as in the /stats listing, then the others by label.
function Characters.dropdownEntries(db, currentGUID, now)
  local current, others = nil, {}
  for guid, character in pairs(db.characters) do
    local isCurrent = guid == currentGUID
    local entry = {
      guid = guid,
      label = Characters.displayName(character),
      class = character.class,
      lastSynced = character.lastSynced,
      relative = Characters.relativeLastSyncedOf(guid, character, currentGUID, now),
      isCurrent = isCurrent,
    }
    if isCurrent then
      current = entry
    else
      others[#others + 1] = entry
    end
  end
  table.sort(others, function(a, b)
    return a.label < b.label
  end)
  local entries = { current }
  for _, entry in ipairs(others) do
    entries[#entries + 1] = entry
  end
  return entries
end

-- Last Synced of a dropdown entry for the text beside the dropdown, { text, exact }: `text` reads it relative to
-- now, `exact` is its date and time through `formatDate` (the game's date()). The logged-in Character's values are
-- live, so it reads now at the exact time `now`.
function Characters.lastSynced(entry, now, formatDate)
  local syncedAt = entry.isCurrent and now or entry.lastSynced
  return {
    text = string.format(L.LAST_SYNCED, entry.relative),
    exact = formatDate(L.EXACT_DATE_TIME, syncedAt),
  }
end

-- Each Tracked Character's Statistic values, by GUID and as a list for AccountTotals: its saved Snapshot, or
-- `liveValues` for the logged-in Character (`currentGUID`) when given. A Character without a Snapshot has none.
function Characters.statisticValues(db, currentGUID, liveValues)
  local byGUID, all = {}, {}
  for guid, character in pairs(db.characters) do
    local values = guid == currentGUID and liveValues or character.snapshot or {}
    byGUID[guid] = values
    all[#all + 1] = values
  end
  return byGUID, all
end

-- The dropdown entry of the Character selected by `selectedGUID`, or the first entry (the logged-in Character)
-- when none is selected or the selected one is no longer tracked.
function Characters.selectedEntry(entries, selectedGUID)
  for _, entry in ipairs(entries) do
    if entry.guid == selectedGUID then
      return entry
    end
  end
  return entries[1]
end
