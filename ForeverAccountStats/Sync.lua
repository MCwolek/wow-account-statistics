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

-- Stores a Sync of `character` ({ guid, fullName, class }) and returns the db.
-- An empty Snapshot (Statistics not readable at that moment) never replaces an earlier one.
function Sync.record(db, character, snapshot, now)
  db = Sync.ensureDB(db)
  local previous = db.characters[character.guid]
  if previous and next(snapshot) == nil then
    previous.fullName = character.fullName
    previous.class = character.class
    return db
  end
  db.characters[character.guid] = {
    fullName = character.fullName,
    class = character.class,
    lastSynced = now,
    snapshot = snapshot,
  }
  return db
end
