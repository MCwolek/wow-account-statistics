local addon = require("addon")

local function loadListing()
  local ns = addon.loadFile("Locale.lua", {})
  return addon.loadFile("Listing.lua", ns).Listing
end

local MINUTE, HOUR, DAY = 60, 3600, 86400
local NOW = 1700000000

describe("Listing.lastSynced", function()
  local Listing = loadListing()

  it("counts whole days", function()
    assert.are.equal("5 d ago", Listing.lastSynced(NOW - 5 * DAY - 7 * HOUR, NOW))
  end)

  it("counts whole hours under a day", function()
    assert.are.equal("23 h ago", Listing.lastSynced(NOW - DAY + 1, NOW))
  end)

  it("counts whole minutes under an hour", function()
    assert.are.equal("1 min ago", Listing.lastSynced(NOW - MINUTE - 30, NOW))
  end)

  it("is now under a minute", function()
    assert.are.equal("now", Listing.lastSynced(NOW - 59, NOW))
    assert.are.equal("now", Listing.lastSynced(NOW, NOW))
  end)
end)

describe("Listing.lines", function()
  local Listing = loadListing()

  local db = {
    characters = {
      ["Player-1-0000BBBB"] = { fullName = "Mira Stonehand", lastSynced = NOW - 5 * DAY },
      ["Player-1-0000AAAA"] = { fullName = "Calgan Blackbeard", lastSynced = NOW - 2 * HOUR },
      ["Player-1-0000CCCC"] = { fullName = "Arlen", lastSynced = NOW - 3 * MINUTE },
    },
  }

  it("lists every Tracked Character by Full Name, the logged-in one as now", function()
    assert.are.same({
      "Forever Account Stats: Tracked Characters (3)",
      "  Arlen - 3 min ago",
      "  Calgan Blackbeard - now",
      "  Mira Stonehand - 5 d ago",
    }, Listing.lines(db, "Player-1-0000AAAA", NOW))
  end)
end)
