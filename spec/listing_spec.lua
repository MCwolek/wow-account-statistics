local addon = require("addon")

local coins = require("coins")

local function loadListing()
  local ns = addon.loadFile("Locale.lua", {})
  addon.loadFile("Values.lua", ns)
  addon.loadFile("Roster.lua", ns)
  addon.loadFile("AccountStatistics.lua", ns)
  return addon.loadFile("Listing.lua", ns).Listing
end

local HOUR, DAY = 3600, 86400
local NOW = 1700000000

describe("Listing.lines", function()
  local Listing = loadListing()

  local db = {
    characters = {
      ["Player-1-0000AAAA"] = { fullName = "Calgan Blackbeard", ruleset = "PvP", lastSynced = NOW - 2 * HOUR },
      ["Player-1-0000BBBB"] = { fullName = "Mira Stonehand", ruleset = "PvP", lastSynced = NOW - 5 * DAY },
    },
  }

  it("counts the Tracked Characters, then gives each one's label and relative Last Synced", function()
    assert.are.same({
      "Forever Account Stats: Tracked Characters (2)",
      "  Calgan Blackbeard (PvP) - now",
      "  Mira Stonehand (PvP) - 5 d ago",
    }, Listing.lines(db, "Player-1-0000AAAA", NOW))
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

  it("shows each Tracked Character's value as saved in its Snapshot, then the Account Total", function()
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
