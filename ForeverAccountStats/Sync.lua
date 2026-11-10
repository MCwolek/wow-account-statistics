-- Pure Sync logic: turns plain data read from the game into Snapshots and Tracked Characters.
local _, ns = ...

local Sync = {}
ns.Sync = Sync

-- Full Name from the returns of UnitName("player"). On Forever the second return is the Surname, not a realm.
function Sync.fullName(firstName, surname)
  if surname == nil or surname == "" then
    return firstName
  end
  return firstName .. " " .. surname
end

-- Ruleset from the realm name: on Forever each Ruleset is one realm whose name ends in it,
-- e.g. "CAMWOW EU4 Realm 5 PvE" is PvE.
function Sync.ruleset(realmName)
  if realmName == nil or realmName == "" then
    return nil
  end
  return realmName:match("(%S+)%s*$")
end

-- The Character ({ guid, fullName, ruleset, class }) from a raw player reading
-- ({ guid, firstName, surname, realmName, classFile }).
function Sync.character(reading)
  return {
    guid = reading.guid,
    fullName = Sync.fullName(reading.firstName, reading.surname),
    ruleset = Sync.ruleset(reading.realmName),
    class = reading.classFile,
  }
end

-- Snapshot from a list of { id = statisticID, value = displayString } readings.
-- Values stay the raw display strings GetStatistic returns; parsing them is a separate concern.
function Sync.buildSnapshot(readings)
  local snapshot = {}
  for _, reading in ipairs(readings) do
    if reading.id ~= nil and reading.value ~= nil then
      snapshot[reading.id] = reading.value
    end
  end
  return snapshot
end

-- The account-wide SavedVariables table, created or completed as needed.
function Sync.ensureDB(db)
  db = db or {}
  db.characters = db.characters or {}
  return db
end

-- A Snapshot is readable when at least one Statistic has a value other than "--".
-- At login the Statistics may not be loaded yet: then every value reads "--", or none can be read at all.
local function isReadable(snapshot)
  for _, value in pairs(snapshot) do
    if not ns.Values.isNeverHappened(value) then
      return true
    end
  end
  return false
end

-- Stores a Sync of `character` ({ guid, fullName, ruleset, class }) and returns the db.
-- An unreadable Snapshot never replaces an earlier one, and then Last Synced stays as it was.
function Sync.record(db, character, snapshot, now)
  db = Sync.ensureDB(db)
  local entry = db.characters[character.guid]
  if not entry then
    entry = {}
    db.characters[character.guid] = entry
  end
  entry.fullName = character.fullName
  entry.ruleset = character.ruleset
  entry.class = character.class
  if entry.snapshot == nil or isReadable(snapshot) then
    entry.snapshot = snapshot
    entry.lastSynced = now
  end
  return db
end

-- Forgets the Tracked Character `guid`: removes it and its Snapshot, so it no longer counts in Account Totals.
-- The logged-in Character (`currentGUID`) is never forgotten: it would be tracked again at its next Sync anyway.
-- Returns the db.
function Sync.forget(db, guid, currentGUID)
  db = Sync.ensureDB(db)
  if guid ~= currentGUID then
    db.characters[guid] = nil
  end
  return db
end
