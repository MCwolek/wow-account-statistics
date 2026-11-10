local addon = require("addon")

local function loadCharacters()
  local ns = addon.loadFile("Locale.lua", {})
  return addon.loadFile("Characters.lua", ns).Characters
end

local MINUTE, HOUR, DAY = 60, 3600, 86400
local NOW = 1700000000

describe("Characters.relativeLastSynced", function()
  local Characters = loadCharacters()

  it("counts whole days", function()
    assert.are.equal("5 d ago", Characters.relativeLastSynced(NOW - 5 * DAY - 7 * HOUR, NOW))
  end)

  it("counts whole hours under a day", function()
    assert.are.equal("23 h ago", Characters.relativeLastSynced(NOW - DAY + 1, NOW))
  end)

  it("counts whole minutes under an hour", function()
    assert.are.equal("1 min ago", Characters.relativeLastSynced(NOW - MINUTE - 30, NOW))
  end)

  it("is now under a minute", function()
    assert.are.equal("now", Characters.relativeLastSynced(NOW - 59, NOW))
    assert.are.equal("now", Characters.relativeLastSynced(NOW, NOW))
  end)
end)

describe("Characters.relativeLastSyncedOf", function()
  local Characters = loadCharacters()

  local GUID = "Player-1-0000AAAA"
  local character = { fullName = "Calgan Blackbeard", lastSynced = NOW - 2 * HOUR }

  it("reads another Character's Last Synced relative to now", function()
    assert.are.equal("2 h ago", Characters.relativeLastSyncedOf(GUID, character, "Player-1-0000BBBB", NOW))
  end)

  it("reads the logged-in Character as now, whatever its saved Last Synced", function()
    assert.are.equal("now", Characters.relativeLastSyncedOf(GUID, character, GUID, NOW))
  end)
end)

describe("Characters.dropdownEntries", function()
  local Characters = loadCharacters()

  local db = {
    characters = {
      ["Player-1-0000BBBB"] = {
        fullName = "Mira Stonehand", ruleset = "PvP", class = "PRIEST", lastSynced = NOW - 5 * DAY,
      },
      ["Player-1-0000AAAA"] = {
        fullName = "Calgan Blackbeard", ruleset = "PvP", class = "WARRIOR", lastSynced = NOW - 2 * HOUR,
      },
      ["Player-2-0000DDDD"] = {
        fullName = "Calgan Blackbeard", ruleset = "PvE", class = "MAGE", lastSynced = NOW - 2 * DAY,
      },
      ["Player-1-0000CCCC"] = { fullName = "Arlen", class = "ROGUE", lastSynced = NOW - 3 * MINUTE },
    },
  }

  it("puts the logged-in Character first as now, then the others by Full Name and Ruleset", function()
    assert.are.same({
      {
        guid = "Player-1-0000AAAA", label = "Calgan Blackbeard (PvP)", class = "WARRIOR",
        lastSynced = NOW - 2 * HOUR, relative = "now", isCurrent = true,
      },
      {
        guid = "Player-1-0000CCCC", label = "Arlen", class = "ROGUE",
        lastSynced = NOW - 3 * MINUTE, relative = "3 min ago", isCurrent = false,
      },
      {
        guid = "Player-2-0000DDDD", label = "Calgan Blackbeard (PvE)", class = "MAGE",
        lastSynced = NOW - 2 * DAY, relative = "2 d ago", isCurrent = false,
      },
      {
        guid = "Player-1-0000BBBB", label = "Mira Stonehand (PvP)", class = "PRIEST",
        lastSynced = NOW - 5 * DAY, relative = "5 d ago", isCurrent = false,
      },
    }, Characters.dropdownEntries(db, "Player-1-0000AAAA", NOW))
  end)
end)

describe("Characters.selectedEntry", function()
  local Characters = loadCharacters()

  local entries = {
    { guid = "Player-1-0000AAAA", label = "Calgan Blackbeard (PvP)", isCurrent = true },
    { guid = "Player-1-0000BBBB", label = "Mira Stonehand (PvP)", isCurrent = false },
  }

  it("is the entry of the selected Character", function()
    assert.are.equal(entries[2], Characters.selectedEntry(entries, "Player-1-0000BBBB"))
  end)

  it("is the logged-in Character when none is selected yet", function()
    assert.are.equal(entries[1], Characters.selectedEntry(entries, nil))
  end)

  it("is the logged-in Character when the selected one is no longer tracked", function()
    assert.are.equal(entries[1], Characters.selectedEntry(entries, "Player-1-0000FFFF"))
  end)
end)

describe("Characters.lastSyncedTooltip", function()
  local Characters = loadCharacters()

  -- Local time, as the game's date() formats it.
  local now = os.time({ year = 2026, month = 11, day = 7, hour = 10, min = 5, sec = 30 })

  it("gives another Character's Last Synced as a date and time", function()
    local entry = { lastSynced = now - 2 * DAY - 3 * HOUR, relative = "2 d ago", isCurrent = false }
    assert.are.equal("Last sync: 2026-11-05 07:05", Characters.lastSyncedTooltip(entry, now, os.date))
  end)

  it("gives now for the logged-in Character, since its values are live", function()
    local entry = { lastSynced = now - 3 * HOUR, relative = "now", isCurrent = true }
    assert.are.equal("Last sync: 2026-11-07 10:05", Characters.lastSyncedTooltip(entry, now, os.date))
  end)
end)

describe("Characters.statisticValues", function()
  local Characters = loadCharacters()

  local CURRENT, OTHER, NEW = "Player-1-0000AAAA", "Player-1-0000BBBB", "Player-1-0000CCCC"
  local db = {
    characters = {
      [CURRENT] = { fullName = "Calgan Blackbeard", snapshot = { [60] = "2" } },
      [OTHER] = { fullName = "Mira Stonehand", snapshot = { [60] = "3" } },
      [NEW] = { fullName = "Arlen" },
    },
  }

  -- `all` lists the same tables as `byGUID`, in no particular order.
  local function assertListsEach(byGUID, all)
    local count = 0
    for _ in pairs(byGUID) do
      count = count + 1
    end
    assert.are.equal(count, #all)
    for _, values in ipairs(all) do
      local found = false
      for _, expected in pairs(byGUID) do
        found = found or rawequal(values, expected)
      end
      assert.is_true(found)
    end
  end

  it("gives each Tracked Character its saved Snapshot, by GUID and as a list", function()
    local byGUID, all = Characters.statisticValues(db)
    assert.are.same({ [CURRENT] = { [60] = "2" }, [OTHER] = { [60] = "3" }, [NEW] = {} }, byGUID)
    assertListsEach(byGUID, all)
  end)

  it("gives the logged-in Character its live values in place of its Snapshot", function()
    local byGUID, all = Characters.statisticValues(db, CURRENT, { [60] = "5" })
    assert.are.same({ [CURRENT] = { [60] = "5" }, [OTHER] = { [60] = "3" }, [NEW] = {} }, byGUID)
    assertListsEach(byGUID, all)
  end)
end)

describe("a forgotten Character", function()
  local ns = addon.loadFile("Sync.lua", addon.loadFile("Values.lua", addon.loadFile("Locale.lua", {})))
  local Characters = addon.loadFile("Characters.lua", ns).Characters
  local Sync = ns.Sync

  local CURRENT, FORGOTTEN = "Player-1-0000AAAA", "Player-1-0000BBBB"
  local function forgotten()
    local db = Sync.record(nil, { guid = CURRENT, fullName = "Calgan Blackbeard" }, { [60] = "250" }, NOW)
    db = Sync.record(db, { guid = FORGOTTEN, fullName = "Mira Stonehand" }, { [60] = "3" }, NOW)
    return Sync.forget(db, FORGOTTEN, CURRENT)
  end

  it("is gone from the dropdown", function()
    local entries = Characters.dropdownEntries(forgotten(), CURRENT, NOW)
    assert.are.equal(1, #entries)
    assert.are.equal(CURRENT, entries[1].guid)
  end)

  it("no longer counts in the Account Totals", function()
    local _, all = Characters.statisticValues(forgotten(), CURRENT)
    assert.are.same({ { [60] = "250" } }, all)
  end)
end)
