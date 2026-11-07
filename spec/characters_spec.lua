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

describe("Characters.lastSynced", function()
  local Characters = loadCharacters()

  -- Local time, as the game's date() formats it.
  local now = os.time({ year = 2026, month = 11, day = 7, hour = 10, min = 5, sec = 30 })

  it("reads another Character's Last Synced relative to now, with its exact date and time", function()
    local entry = { lastSynced = now - 2 * DAY - 3 * HOUR, relative = "2 d ago", isCurrent = false }
    assert.are.same(
      { text = "Last Synced: 2 d ago", exact = "2026-11-05 07:05" },
      Characters.lastSynced(entry, now, os.date)
    )
  end)

  it("reads the logged-in Character's Last Synced as now, since its values are live", function()
    local entry = { lastSynced = now - 3 * HOUR, relative = "now", isCurrent = true }
    assert.are.same(
      { text = "Last Synced: now", exact = "2026-11-07 10:05" },
      Characters.lastSynced(entry, now, os.date)
    )
  end)
end)
