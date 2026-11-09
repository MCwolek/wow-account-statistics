local addon = require("addon")
local coins = require("coins")
local gold, silver, copper = coins.gold, coins.silver, coins.copper

local function loadBreakdown()
  local ns = addon.loadFile("Locale.lua", {})
  addon.loadFile("Values.lua", ns)
  addon.loadFile("AccountTotals.lua", ns)
  addon.loadFile("Characters.lua", ns)
  return addon.loadFile("Breakdown.lua", ns).Breakdown
end

-- One Tracked Character per name, each with `snapshot` as its saved Snapshot.
local function db(snapshots)
  local characters = {}
  for name, snapshot in pairs(snapshots) do
    characters["Player-1-" .. name] = { fullName = name, class = "WARRIOR", snapshot = snapshot }
  end
  return { characters = characters }
end

local function labelsAndValues(breakdown)
  local result = {}
  for _, line in ipairs(breakdown.lines) do
    result[#result + 1] = line.label .. " " .. line.value
  end
  return result
end

describe("Breakdown.build", function()
  local Breakdown = loadBreakdown()

  it("lists every Tracked Character's value from highest to lowest", function()
    -- 60 Total deaths
    local view = { db = db({ Calgan = { [60] = "3" }, Mira = { [60] = "12" }, Keram = { [60] = "7" } }) }
    assert.are.same({ "Mira 12", "Keram 7", "Calgan 3" }, labelsAndValues(Breakdown.build(60, view)))
  end)

  it("lists -- after every value, then ? for a Snapshot without the Statistic", function()
    local view = { db = db({ Ana = {}, Bron = { [60] = "--" }, Calgan = { [60] = "1" }, Dara = { [60] = "--" } }) }
    assert.are.same({ "Calgan 1", "Bron --", "Dara --", "Ana ?" }, labelsAndValues(Breakdown.build(60, view)))
  end)

  it("lists the top 5 and counts the other Tracked Characters", function()
    local view = { db = db({
      A = { [60] = "1" }, B = { [60] = "2" }, C = { [60] = "3" }, D = { [60] = "4" },
      E = { [60] = "5" }, F = { [60] = "6" }, G = { [60] = "--" },
    }) }
    local breakdown = Breakdown.build(60, view)
    assert.are.same({ "F 6", "E 5", "D 4", "C 3", "B 2" }, labelsAndValues(breakdown))
    assert.are.equal(2, breakdown.more)
  end)

  it("counts no others with 5 Tracked Characters or fewer", function()
    local view = { db = db({ A = { [60] = "1" }, B = { [60] = "2" }, C = { [60] = "3" }, D = { [60] = "4" },
      E = { [60] = "5" } }) }
    local breakdown = Breakdown.build(60, view)
    assert.are.equal(5, #breakdown.lines)
    assert.are.equal(0, breakdown.more)
  end)

  it("sorts money by its amount and keeps the coin icons", function()
    -- 328 Total gold acquired
    local rich = gold(1) .. " " .. copper(5)
    local poor = silver(90) .. " " .. copper(27)
    local view = { db = db({ Ana = { [328] = poor }, Bron = { [328] = "--" }, Calgan = { [328] = rich } }) }
    assert.are.same({ "Calgan " .. rich, "Ana " .. poor, "Bron --" }, labelsAndValues(Breakdown.build(328, view)))
  end)

  it("is nil for a Statistic without an Account Total", function()
    -- 1336 Creature type killed the most, 95 Average quests completed per day
    assert.is_nil(Breakdown.build(1336, { db = db({ Ana = { [1336] = "62 (Beasts)" }, Bron = { [1336] = "--" } }) }))
    assert.is_nil(Breakdown.build(95, { db = db({ Ana = { [95] = "27" } }) }))
  end)

  it("is nil when no Character's Snapshot has the Statistic", function()
    -- e.g. "Most Horde factions at Exalted" on an Account of Alliance Characters only.
    assert.is_nil(Breakdown.build(926, { db = db({ Ana = {}, Bron = { [60] = "3" } }) }))
  end)

  it("names each Character with its Ruleset and class, and reads the logged-in Character's live values", function()
    local current, other = "Player-1-0000AAAA", "Player-1-0000BBBB"
    local view = {
      db = { characters = {
        [current] = { fullName = "Calgan Blackbeard", ruleset = "PvE", class = "MAGE", snapshot = { [60] = "2" } },
        [other] = { fullName = "Mira Stonehand", ruleset = "PvP", class = "ROGUE", snapshot = { [60] = "3" } },
      } },
      currentGUID = current,
      liveValues = { [60] = "5" },
    }
    assert.are.same({
      lines = {
        { label = "Calgan Blackbeard (PvE)", class = "MAGE", value = "5" },
        { label = "Mira Stonehand (PvP)", class = "ROGUE", value = "3" },
      },
      more = 0,
    }, Breakdown.build(60, view))
  end)

  it("lists equal values by name", function()
    local view = { db = db({ Dara = { [60] = "4" }, Bron = { [60] = "4" }, Calgan = { [60] = "9" } }) }
    assert.are.same({ "Calgan 9", "Bron 4", "Dara 4" }, labelsAndValues(Breakdown.build(60, view)))
  end)

  it("lists a Peak Statistic's values highest first, the top one being the Account Total", function()
    -- 193 Largest hit dealt
    local view = { db = db({ Ana = { [193] = "54" }, Bron = { [193] = "87" } }) }
    assert.are.same({ "Bron 87", "Ana 54" }, labelsAndValues(Breakdown.build(193, view)))
  end)
end)
