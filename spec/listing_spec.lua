local addon = require("addon")

local function loadListing()
  local ns = addon.loadFile("Locale.lua", {})
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
