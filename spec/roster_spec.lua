local addon = require("addon")

local function loadRoster()
  local ns = addon.loadFile("Locale.lua", {})
  return addon.loadFile("Roster.lua", ns).Roster
end

local MINUTE, HOUR, DAY = 60, 3600, 86400
local NOW = 1700000000

-- The Roster's Full Names and Rulesets (`label`), in its order.
local function labels(roster)
  local result = {}
  for i, entry in ipairs(roster) do
    result[i] = entry.label
  end
  return result
end

describe("Roster.of", function()
  local Roster = loadRoster()

  it("names every Tracked Character by Full Name and Ruleset, in that order", function()
    local db = {
      characters = {
        ["Player-1-0000BBBB"] = { fullName = "Mira Stonehand", ruleset = "PvP", lastSynced = NOW },
        ["Player-1-0000AAAA"] = { fullName = "Calgan Blackbeard", ruleset = "PvP", lastSynced = NOW },
        ["Player-2-0000DDDD"] = { fullName = "Calgan Blackbeard", ruleset = "PvE", lastSynced = NOW },
        ["Player-1-0000CCCC"] = { fullName = "Arlen", ruleset = "PvE", lastSynced = NOW },
      },
    }
    assert.are.same({
      "Arlen (PvE)", "Calgan Blackbeard (PvE)", "Calgan Blackbeard (PvP)", "Mira Stonehand (PvP)",
    }, labels(Roster.of(db, "Player-1-0000AAAA", NOW)))
  end)

  it("names a Character synced before Rulesets were saved by its Full Name alone", function()
    local db = {
      characters = {
        ["Player-1-0000AAAA"] = { fullName = "Calgan Blackbeard", lastSynced = NOW },
        ["Player-1-0000BBBB"] = { fullName = "Arlen", ruleset = "PvE", lastSynced = NOW },
      },
    }
    assert.are.same({ "Arlen (PvE)", "Calgan Blackbeard" }, labels(Roster.of(db, "Player-1-0000AAAA", NOW)))
  end)

  it("marks the logged-in Character, its Last Synced now, whatever it saved; the others' as saved", function()
    local db = {
      characters = {
        ["Player-1-0000AAAA"] = {
          fullName = "Calgan Blackbeard", ruleset = "PvP", class = "WARRIOR", lastSynced = NOW - 2 * HOUR,
        },
        ["Player-1-0000BBBB"] = {
          fullName = "Mira Stonehand", ruleset = "PvP", class = "PRIEST", lastSynced = NOW - 5 * DAY,
        },
      },
    }
    assert.are.same({
      {
        guid = "Player-1-0000AAAA", label = "Calgan Blackbeard (PvP)", class = "WARRIOR", isCurrent = true,
        lastSynced = NOW, relativeLastSynced = "now",
      },
      {
        guid = "Player-1-0000BBBB", label = "Mira Stonehand (PvP)", class = "PRIEST", isCurrent = false,
        lastSynced = NOW - 5 * DAY, relativeLastSynced = "5 d ago",
      },
    }, Roster.of(db, "Player-1-0000AAAA", NOW))
  end)

  it("gives each Tracked Character its Faction, none to one synced before Factions were recorded", function()
    local db = {
      characters = {
        ["Player-1-0000AAAA"] = { fullName = "Arlen", faction = "Alliance", lastSynced = NOW },
        ["Player-1-0000BBBB"] = { fullName = "Calgan Blackbeard", faction = "Horde", lastSynced = NOW },
        ["Player-1-0000CCCC"] = { fullName = "Mira Stonehand", lastSynced = NOW },
      },
    }
    local roster = Roster.of(db, "Player-1-0000AAAA", NOW)
    assert.are.same({ "Alliance", "Horde" }, { roster[1].faction, roster[2].faction })
    assert.is_nil(roster[3].faction)
  end)

  describe("relative Last Synced", function()
    -- relativeLastSynced of a Character other than the logged-in one, last Synced at `syncedAt`.
    local function relativeOf(syncedAt)
      local db = { characters = { ["Player-1-0000BBBB"] = { fullName = "Mira Stonehand", lastSynced = syncedAt } } }
      return Roster.of(db, "Player-1-0000AAAA", NOW)[1].relativeLastSynced
    end

    it("counts whole days", function()
      assert.are.equal("5 d ago", relativeOf(NOW - 5 * DAY - 7 * HOUR))
    end)

    it("counts whole hours under a day", function()
      assert.are.equal("23 h ago", relativeOf(NOW - DAY + 1))
    end)

    it("counts whole minutes under an hour", function()
      assert.are.equal("1 min ago", relativeOf(NOW - MINUTE - 30))
    end)

    it("is now under a minute", function()
      assert.are.equal("now", relativeOf(NOW - 59))
      assert.are.equal("now", relativeOf(NOW))
    end)
  end)
end)

describe("a forgotten Character", function()
  local ns = addon.loadFile("Sync.lua", addon.loadFile("Values.lua", addon.loadFile("Locale.lua", {})))
  local Roster = addon.loadFile("Roster.lua", ns).Roster
  local Sync = ns.Sync

  local CURRENT, FORGOTTEN = "Player-1-0000AAAA", "Player-1-0000BBBB"

  it("is gone from the Roster", function()
    local db = Sync.record(nil, { guid = CURRENT, fullName = "Calgan Blackbeard" }, { [60] = "250" }, NOW)
    db = Sync.record(db, { guid = FORGOTTEN, fullName = "Mira Stonehand" }, { [60] = "3" }, NOW)
    db = Sync.forget(db, FORGOTTEN, CURRENT)
    assert.are.same({ "Calgan Blackbeard" }, labels(Roster.of(db, CURRENT, NOW)))
  end)
end)
