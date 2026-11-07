local addon = require("addon")

local coins = require("coins")

local function loadListing()
  local ns = addon.loadFile("Locale.lua", {})
  addon.loadFile("Values.lua", ns)
  addon.loadFile("AccountTotals.lua", ns)
  return addon.loadFile("Listing.lua", ns).Listing
end

local MINUTE, HOUR, DAY = 60, 3600, 86400
local NOW = 1700000000

describe("Listing.relativeLastSynced", function()
  local Listing = loadListing()

  it("counts whole days", function()
    assert.are.equal("5 d ago", Listing.relativeLastSynced(NOW - 5 * DAY - 7 * HOUR, NOW))
  end)

  it("counts whole hours under a day", function()
    assert.are.equal("23 h ago", Listing.relativeLastSynced(NOW - DAY + 1, NOW))
  end)

  it("counts whole minutes under an hour", function()
    assert.are.equal("1 min ago", Listing.relativeLastSynced(NOW - MINUTE - 30, NOW))
  end)

  it("is now under a minute", function()
    assert.are.equal("now", Listing.relativeLastSynced(NOW - 59, NOW))
    assert.are.equal("now", Listing.relativeLastSynced(NOW, NOW))
  end)
end)

describe("Listing.lines", function()
  local Listing = loadListing()

  local db = {
    characters = {
      ["Player-1-0000BBBB"] = { fullName = "Mira Stonehand", ruleset = "PvP", lastSynced = NOW - 5 * DAY },
      ["Player-1-0000AAAA"] = { fullName = "Calgan Blackbeard", ruleset = "PvP", lastSynced = NOW - 2 * HOUR },
      ["Player-2-0000DDDD"] = { fullName = "Calgan Blackbeard", ruleset = "PvE", lastSynced = NOW - 2 * DAY },
      ["Player-1-0000CCCC"] = { fullName = "Arlen", ruleset = "PvE", lastSynced = NOW - 3 * MINUTE },
    },
  }

  it("lists every Tracked Character by Full Name and Ruleset, the logged-in one as now", function()
    assert.are.same({
      "Forever Account Stats: Tracked Characters (4)",
      "  Arlen (PvE) - 3 min ago",
      "  Calgan Blackbeard (PvE) - 2 d ago",
      "  Calgan Blackbeard (PvP) - now",
      "  Mira Stonehand (PvP) - 5 d ago",
    }, Listing.lines(db, "Player-1-0000AAAA", NOW))
  end)

  it("leaves out the Ruleset for a Character synced before Rulesets were saved", function()
    local old = { characters = { ["Player-1-0000AAAA"] = { fullName = "Calgan Blackbeard", lastSynced = NOW } } }
    assert.are.same({
      "Forever Account Stats: Tracked Characters (1)",
      "  Calgan Blackbeard - now",
    }, Listing.lines(old, "Player-1-0000AAAA", NOW))
  end)
end)

describe("Listing.parseCommand", function()
  local Listing = loadListing()

  it("lists Tracked Characters with no arguments", function()
    assert.are.same({ action = "list" }, Listing.parseCommand(""))
    assert.are.same({ action = "list" }, Listing.parseCommand("   "))
  end)

  it("dumps one Statistic by ID, ignoring case and extra spaces", function()
    assert.are.same({ action = "dump", statisticID = 60 }, Listing.parseCommand("dump 60"))
    assert.are.same({ action = "dump", statisticID = 328 }, Listing.parseCommand("  DUMP   328 "))
  end)

  it("shows usage for anything else", function()
    assert.are.same({ action = "usage" }, Listing.parseCommand("dump"))
    assert.are.same({ action = "usage" }, Listing.parseCommand("dump deaths"))
    assert.are.same({ action = "usage" }, Listing.parseCommand("dump 60 61"))
    assert.are.same({ action = "usage" }, Listing.parseCommand("help"))
  end)
end)

describe("Listing.statisticLines", function()
  local Listing = loadListing()

  local db = {
    characters = {
      ["Player-1-0000BBBB"] = {
        fullName = "Mira Stonehand", ruleset = "PvP",
        snapshot = { [60] = "3", [328] = coins.silver(14) .. " " .. coins.copper(56), [1336] = "62 (Beasts)" },
      },
      ["Player-1-0000AAAA"] = {
        fullName = "Calgan Blackbeard", ruleset = "PvE",
        snapshot = { [60] = "--", [328] = coins.gold(1) .. " " .. coins.silver(64) .. " " .. coins.copper(39),
          [1336] = "281 (Humanoid)" },
      },
      ["Player-1-0000CCCC"] = { fullName = "Arlen", ruleset = "PvE", snapshot = { [60] = "12" } },
    },
  }

  it("shows each Tracked Character's value as the game shows it, then the Account Total", function()
    assert.are.same({
      "Forever Account Stats: Total deaths (60)",
      "  Arlen (PvE) - 12",
      "  Calgan Blackbeard (PvE) - --",
      "  Mira Stonehand (PvP) - 3",
      "  Account Total: 15",
    }, Listing.statisticLines(db, 60, "Total deaths"))
  end)

  it("marks a Statistic missing from a Snapshot and sums money with coin icons", function()
    assert.are.same({
      "Forever Account Stats: Total gold acquired (328)",
      "  Arlen (PvE) - ?",
      "  Calgan Blackbeard (PvE) - " .. coins.gold(1) .. " " .. coins.silver(64) .. " " .. coins.copper(39),
      "  Mira Stonehand (PvP) - " .. coins.silver(14) .. " " .. coins.copper(56),
      "  Account Total: " .. coins.gold(1) .. " " .. coins.silver(78) .. " " .. coins.copper(95),
    }, Listing.statisticLines(db, 328, "Total gold acquired"))
  end)

  it("shows no Account Total for a Text Statistic", function()
    local lines = Listing.statisticLines(db, 1336, "Creature type killed the most")
    assert.are.equal("  Account Total: —", lines[#lines])
  end)

  it("names a Statistic the game does not know as unknown", function()
    assert.are.equal("Forever Account Stats: Unknown Statistic (99999)", Listing.statisticLines(db, 99999, nil)[1])
  end)
end)
