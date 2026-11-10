local addon = require("addon")
local coins = require("coins")
local gold, silver, copper = coins.gold, coins.silver, coins.copper

local function loadAccountStatistics()
  local ns = addon.loadFile("Locale.lua", {})
  addon.loadFile("Values.lua", ns)
  addon.loadFile("Roster.lua", ns)
  return addon.loadFile("AccountStatistics.lua", ns).AccountStatistics
end

local CURRENT, OTHER, NEW = "Player-1-0000AAAA", "Player-1-0000BBBB", "Player-1-0000CCCC"
local NOW = 1700000000

describe("AccountStatistics:value", function()
  local AccountStatistics = loadAccountStatistics()

  local db = {
    characters = {
      [CURRENT] = { fullName = "Calgan Blackbeard", lastSynced = NOW, snapshot = { [60] = "2" } },
      [OTHER] = { fullName = "Mira Stonehand", lastSynced = NOW, snapshot = { [60] = "3", [98] = "--" } },
      [NEW] = { fullName = "Arlen", lastSynced = NOW },
    },
  }

  it("reads another Character's value from its saved Snapshot, as the game shows it", function()
    local statistics = AccountStatistics.new(db, CURRENT, NOW, { [60] = "5" })
    assert.are.equal("3", statistics:value(OTHER, 60))
    assert.are.equal("--", statistics:value(OTHER, 98))
  end)

  it("reads the logged-in Character's Live Values in place of its saved Snapshot", function()
    local statistics = AccountStatistics.new(db, CURRENT, NOW, { [60] = "5" })
    assert.are.equal("5", statistics:value(CURRENT, 60))
  end)

  it("reads every Character's saved Snapshot when given no Live Values, as /stats dump does", function()
    local statistics = AccountStatistics.new(db, CURRENT, NOW)
    assert.are.equal("2", statistics:value(CURRENT, 60))
    assert.are.equal("3", statistics:value(OTHER, 60))
  end)

  it("marks a value missing from the Snapshot, or of a Character not tracked, with ?", function()
    local statistics = AccountStatistics.new(db, CURRENT, NOW, { [60] = "5" })
    assert.are.equal("?", statistics:value(OTHER, 1336))
    assert.are.equal("?", statistics:value(NEW, 60))
    assert.are.equal("?", statistics:value("Player-1-0000FFFF", 60))
    assert.are.equal("?", statistics:value(nil, 60))
  end)
end)

describe("AccountStatistics:characterValues", function()
  local AccountStatistics = loadAccountStatistics()

  it("gives every Tracked Character's value with its Full Name, Ruleset and class, in Roster order", function()
    local db = {
      characters = {
        [CURRENT] = {
          fullName = "Calgan Blackbeard", lastSynced = NOW, ruleset = "PvE", class = "MAGE", snapshot = { [60] = "2" },
        },
        [OTHER] = {
          fullName = "Mira Stonehand", lastSynced = NOW, ruleset = "PvP", class = "ROGUE", snapshot = { [60] = "--" },
        },
      },
    }
    assert.are.same({
      { label = "Calgan Blackbeard (PvE)", class = "MAGE", value = "5" },
      { label = "Mira Stonehand (PvP)", class = "ROGUE", value = "--" },
    }, AccountStatistics.new(db, CURRENT, NOW, { [60] = "5" }):characterValues(60))
  end)
end)

-- Values from real Snapshots of Schalgan Blackbeard and Keram.
local blackbeard = {
  [60] = "--",
  [98] = "27",
  [107] = "468",
  [326] = silver(7) .. " " .. copper(27),
}
local keram = {
  [60] = "3",
  [98] = "84",
  [107] = "514",
  [326] = silver(63) .. " " .. copper(10),
}

describe("AccountStatistics:accountTotal", function()
  local AccountStatistics = loadAccountStatistics()

  -- The Account Total of `statisticID` over one Tracked Character per Snapshot given, with no Live Values.
  local function total(statisticID, snapshots)
    local characters = {}
    for i, snapshot in ipairs(snapshots) do
      characters["Player-1-" .. i] = { fullName = "Character " .. i, lastSynced = NOW, snapshot = snapshot }
    end
    return AccountStatistics.new({ characters = characters }, CURRENT, NOW):accountTotal(statisticID)
  end

  it("sums a Statistic across Tracked Characters as plain digits", function()
    assert.are.equal("111", total(98, { blackbeard, keram }))
    assert.are.equal("982", total(107, { blackbeard, keram }))
  end)

  it("counts -- as 0", function()
    assert.are.equal("3", total(60, { blackbeard, keram }))
  end)

  it("sums money in copper and shows it with coin icons like the default UI", function()
    assert.are.equal(silver(70) .. " " .. copper(37), total(326, { blackbeard, keram }))
  end)

  it("sums money when some Characters read --", function()
    -- 328 Total gold acquired
    local fresh = { [328] = "--" }
    local earner = { [328] = gold(1) .. " " .. silver(64) .. " " .. copper(39) }
    local saver = { [328] = silver(7) .. " " .. copper(27) }
    assert.are.equal(gold(1) .. " " .. silver(71) .. " " .. copper(66), total(328, { fresh, earner, fresh, saver }))
  end)

  it("leaves out a Character whose Snapshot lacks the Statistic", function()
    local older = { [98] = "12" }
    assert.are.equal("982", total(107, { blackbeard, older, keram }))
    assert.are.equal("3", total(60, { blackbeard, {}, keram }))
  end)

  it("shows ? when no Character's Snapshot has the Statistic", function()
    -- e.g. "Most Horde factions at Exalted" on an Account of Alliance Characters only.
    assert.are.equal("?", total(926, { blackbeard, keram }))
    assert.are.equal("?", total(98, {}))
  end)

  it("shows -- when the Statistic never happened on any Character", function()
    assert.are.equal("--", total(60, { blackbeard, blackbeard }))
  end)

  it("shows no Account Total for a Text Statistic", function()
    local beasts = { [1336] = "62 (Beasts)" }
    local humanoid = { [1336] = "281 (Humanoid)" }
    local none = { [1336] = "--" }
    assert.are.equal("—", total(1336, { beasts, humanoid }))
    assert.are.equal("—", total(1336, { none, humanoid, {} }))
  end)

  it("shows no Account Total for a Text Statistic even when every Character reads --", function()
    -- Real Snapshots read -- for all of these, e.g. 1125 Bandage used most, 1458 Continent with the most
    -- Honorable Kills.
    local textStatistics = { 1125, 1336, 1339, 1458, 1489, 1716, 1719 }
    for _, id in ipairs(textStatistics) do
      assert.are.equal("—", total(id, { { [id] = "--" }, { [id] = "--" } }), "Statistic " .. id)
    end
  end)

  it("shows no Account Total for a value shaped like text, whatever the Statistic", function()
    assert.are.equal("—", total(98, { { [98] = "27" }, { [98] = "62 (Beasts)" } }))
  end)

  it("shows no Account Total for an Average Statistic", function()
    local first = {
      [95] = "27",
      [753] = silver(14) .. " " .. copper(56),
    }
    local second = {
      [95] = "84",
      [753] = gold(1) .. " " .. silver(64) .. " " .. copper(39),
    }
    assert.are.equal("—", total(95, { first, second }))
    assert.are.equal("—", total(753, { first, second }))
  end)

  it("takes the highest value of a Peak Statistic", function()
    -- 193 Largest hit dealt
    assert.are.equal("87", total(193, { { [193] = "87" }, { [193] = "54" } }))
  end)

  it("takes the highest money of a Peak Statistic", function()
    -- 334 Most gold ever owned
    local poorer = {
      [334] = silver(11) .. " " .. copper(46),
    }
    local richer = {
      [334] = gold(1) .. " " .. silver(30) .. " " .. copper(39),
    }
    assert.are.equal(gold(1) .. " " .. silver(30) .. " " .. copper(39), total(334, { poorer, richer }))
  end)

  it("keeps the highest money of a Peak Statistic when some Characters read --", function()
    -- 331 Most expensive bid on auction
    local spent = { [331] = "--" }
    local sold = { [331] = silver(2) .. " " .. copper(9) }
    assert.are.equal(silver(2) .. " " .. copper(9), total(331, { spent, sold, spent }))
  end)

  it("counts -- as 0 and leaves out missing values for a Peak Statistic", function()
    -- 1466 Most Alliance factions at Exalted is missing from Horde Characters' Snapshots.
    local horde = { [926] = "1" }
    local alliance = { [926] = "--", [1466] = "--" }
    assert.are.equal("--", total(1466, { horde, alliance }))
    assert.are.equal("1", total(926, { alliance, horde }))
    assert.are.equal("?", total(1466, { horde }))
  end)

  it("treats every hand-picked Peak Statistic as a Peak", function()
    local peaks = {
      189, 193, 281, 331, 332, 334, 338, 339, 377, 378, 527, 529, 829, 926, 931, 1337, 1466,
      1519, 1524, 1527, 1532, 1535, 1536, 1537, 1538, 1539, 1541, 1542, 1544,
    }
    for _, id in ipairs(peaks) do
      assert.are.equal("7", total(id, { { [id] = "5" }, { [id] = "7" } }), "Statistic " .. id)
    end
  end)

  it("still sums Statistics that look like Peaks but count across Characters", function()
    -- 1199 Professions learned, 927 Equipped epic items in item slots
    for _, id in ipairs({ 1199, 927 }) do
      assert.are.equal("12", total(id, { { [id] = "5" }, { [id] = "7" } }), "Statistic " .. id)
    end
  end)

  describe("with the logged-in Character", function()
    local db = {
      characters = {
        [CURRENT] = { fullName = "Calgan Blackbeard", lastSynced = NOW, snapshot = { [60] = "2" } },
        [OTHER] = { fullName = "Mira Stonehand", lastSynced = NOW, snapshot = { [60] = "3" } },
      },
    }

    it("counts its Live Values in place of its saved Snapshot", function()
      assert.are.equal("8", AccountStatistics.new(db, CURRENT, NOW, { [60] = "5" }):accountTotal(60))
    end)

    it("counts its saved Snapshot when given no Live Values, as /stats dump does", function()
      assert.are.equal("5", AccountStatistics.new(db, CURRENT, NOW):accountTotal(60))
    end)
  end)
end)

describe("a forgotten Character", function()
  local ns = addon.loadFile("Sync.lua", addon.loadFile("Values.lua", addon.loadFile("Locale.lua", {})))
  addon.loadFile("Roster.lua", ns)
  local AccountStatistics = addon.loadFile("AccountStatistics.lua", ns).AccountStatistics
  local Sync = ns.Sync

  it("no longer counts in the Account Totals", function()
    local db = Sync.record(nil, { guid = CURRENT, fullName = "Calgan Blackbeard" }, { [60] = "250" }, NOW)
    db = Sync.record(db, { guid = OTHER, fullName = "Mira Stonehand" }, { [60] = "3" }, NOW)
    db = Sync.forget(db, OTHER, CURRENT)
    assert.are.equal("250", AccountStatistics.new(db, CURRENT, NOW):accountTotal(60))
  end)
end)

describe("AccountStatistics:breakdown", function()
  local AccountStatistics = loadAccountStatistics()

  -- One Tracked Character per name, each with `snapshot` as its saved Snapshot, with no Live Values.
  local function statisticsOf(snapshots)
    local characters = {}
    for name, snapshot in pairs(snapshots) do
      characters["Player-1-" .. name] = { fullName = name, lastSynced = NOW, class = "WARRIOR", snapshot = snapshot }
    end
    return AccountStatistics.new({ characters = characters }, CURRENT, NOW)
  end

  local function labelsAndValues(breakdown)
    local result = {}
    for _, line in ipairs(breakdown.lines) do
      result[#result + 1] = line.label .. " " .. line.value
    end
    return result
  end

  it("lists every Tracked Character's value from highest to lowest", function()
    -- 60 Total deaths
    local statistics = statisticsOf({ Calgan = { [60] = "3" }, Mira = { [60] = "12" }, Keram = { [60] = "7" } })
    assert.are.same({ "Mira 12", "Keram 7", "Calgan 3" }, labelsAndValues(statistics:breakdown(60)))
  end)

  it("lists -- after every value, then ? for a Snapshot without the Statistic", function()
    local statistics = statisticsOf({
      Ana = {}, Bron = { [60] = "--" }, Calgan = { [60] = "1" }, Dara = { [60] = "--" },
    })
    assert.are.same({ "Calgan 1", "Bron --", "Dara --", "Ana ?" }, labelsAndValues(statistics:breakdown(60)))
  end)

  it("lists the top 5 and counts the other Tracked Characters", function()
    local statistics = statisticsOf({
      A = { [60] = "1" }, B = { [60] = "2" }, C = { [60] = "3" }, D = { [60] = "4" },
      E = { [60] = "5" }, F = { [60] = "6" }, G = { [60] = "--" },
    })
    local breakdown = statistics:breakdown(60)
    assert.are.same({ "F 6", "E 5", "D 4", "C 3", "B 2" }, labelsAndValues(breakdown))
    assert.are.equal(2, breakdown.more)
  end)

  it("counts no others with 5 Tracked Characters or fewer", function()
    local statistics = statisticsOf({
      A = { [60] = "1" }, B = { [60] = "2" }, C = { [60] = "3" }, D = { [60] = "4" }, E = { [60] = "5" },
    })
    local breakdown = statistics:breakdown(60)
    assert.are.equal(5, #breakdown.lines)
    assert.are.equal(0, breakdown.more)
  end)

  it("sorts money by its amount and keeps the coin icons", function()
    -- 328 Total gold acquired
    local rich = gold(1) .. " " .. copper(5)
    local poor = silver(90) .. " " .. copper(27)
    local statistics = statisticsOf({ Ana = { [328] = poor }, Bron = { [328] = "--" }, Calgan = { [328] = rich } })
    assert.are.same({ "Calgan " .. rich, "Ana " .. poor, "Bron --" }, labelsAndValues(statistics:breakdown(328)))
  end)

  it("is nil for a Statistic without an Account Total", function()
    -- 1336 Creature type killed the most, 95 Average quests completed per day
    assert.is_nil(statisticsOf({ Ana = { [1336] = "62 (Beasts)" }, Bron = { [1336] = "--" } }):breakdown(1336))
    assert.is_nil(statisticsOf({ Ana = { [95] = "27" } }):breakdown(95))
  end)

  it("is nil when no Character's Snapshot has the Statistic", function()
    -- e.g. "Most Horde factions at Exalted" on an Account of Alliance Characters only.
    assert.is_nil(statisticsOf({ Ana = {}, Bron = { [60] = "3" } }):breakdown(926))
  end)

  it("names each Character by Full Name and Ruleset with its class and Faction, counting the Live Values", function()
    local db = {
      characters = {
        [CURRENT] = {
          fullName = "Calgan Blackbeard", lastSynced = NOW, ruleset = "PvE", class = "MAGE", faction = "Horde",
          snapshot = { [60] = "2" },
        },
        [OTHER] = {
          fullName = "Mira Stonehand", lastSynced = NOW, ruleset = "PvP", class = "ROGUE", faction = "Alliance",
          snapshot = { [60] = "3" },
        },
      },
    }
    assert.are.same({
      lines = {
        { label = "Calgan Blackbeard (PvE)", class = "MAGE", faction = "Horde", value = "5" },
        { label = "Mira Stonehand (PvP)", class = "ROGUE", faction = "Alliance", value = "3" },
      },
      more = 0,
    }, AccountStatistics.new(db, CURRENT, NOW, { [60] = "5" }):breakdown(60))
  end)

  it("lists equal values in Roster order", function()
    local statistics = statisticsOf({ Dara = { [60] = "4" }, Bron = { [60] = "4" }, Calgan = { [60] = "9" } })
    assert.are.same({ "Calgan 9", "Bron 4", "Dara 4" }, labelsAndValues(statistics:breakdown(60)))
  end)

  it("lists a Peak Statistic's values highest first, the top one being the Account Total", function()
    -- 193 Largest hit dealt
    local statistics = statisticsOf({ Ana = { [193] = "54" }, Bron = { [193] = "87" } })
    assert.are.same({ "Bron 87", "Ana 54" }, labelsAndValues(statistics:breakdown(193)))
  end)
end)
