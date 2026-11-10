local addon = require("addon")

local function loadSync()
  local ns = addon.loadFile("Values.lua", {})
  return addon.loadFile("Sync.lua", ns).Sync
end

describe("Sync.fullName", function()
  local Sync = loadSync()

  it("joins First Name and Surname with one space", function()
    assert.are.equal("Calgan Blackbeard", Sync.fullName("Calgan", "Blackbeard"))
  end)

  it("is the First Name alone when there is no Surname", function()
    assert.are.equal("Calgan", Sync.fullName("Calgan", nil))
    assert.are.equal("Calgan", Sync.fullName("Calgan", ""))
  end)
end)

describe("Sync.ruleset", function()
  local Sync = loadSync()

  it("is the last word of the realm name", function()
    assert.are.equal("PvE", Sync.ruleset("CAMWOW EU4 Realm 5 PvE"))
    assert.are.equal("RP-PvP", Sync.ruleset("CAMWOW EU4 Realm 7 RP-PvP"))
  end)

  it("is the whole realm name when it has one word", function()
    assert.are.equal("Hardcore", Sync.ruleset("Hardcore"))
  end)

  it("is nil without a realm name", function()
    assert.is_nil(Sync.ruleset(nil))
    assert.is_nil(Sync.ruleset(""))
  end)
end)

describe("Sync.character", function()
  local Sync = loadSync()

  it("builds the Character from the raw player reading", function()
    assert.are.same(
      { guid = "Player-1-0000AAAA", fullName = "Calgan Blackbeard", ruleset = "PvE", class = "WARRIOR" },
      Sync.character({
        guid = "Player-1-0000AAAA",
        firstName = "Calgan",
        surname = "Blackbeard",
        realmName = "CAMWOW EU4 Realm 5 PvE",
        classFile = "WARRIOR",
      })
    )
  end)
end)

describe("Sync.buildSnapshot", function()
  local Sync = loadSync()

  it("keys every Statistic's display value by Statistic ID", function()
    local snapshot = Sync.buildSnapshot({
      { id = 60, value = "250" },
      { id = 98, value = "--" },
      { id = 328, value = "12|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t" },
    })
    assert.are.same({
      [60] = "250",
      [98] = "--",
      [328] = "12|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t",
    }, snapshot)
  end)

  it("skips readings without a value", function()
    assert.are.same({ [60] = "250" }, Sync.buildSnapshot({ { id = 60, value = "250" }, { id = 98 } }))
  end)
end)

describe("Sync.record", function()
  local Sync = loadSync()
  local calgan = { guid = "Player-1-0000AAAA", fullName = "Calgan Blackbeard", ruleset = "PvE", class = "WARRIOR" }

  it("stores the Character under its GUID with Full Name, Ruleset, class, Last Synced and Snapshot", function()
    local db = Sync.record(nil, calgan, { [60] = "250" }, 1700000000)
    assert.are.same({
      fullName = "Calgan Blackbeard",
      ruleset = "PvE",
      class = "WARRIOR",
      lastSynced = 1700000000,
      snapshot = { [60] = "250" },
    }, db.characters["Player-1-0000AAAA"])
  end)

  it("keeps the other Tracked Characters", function()
    local db = Sync.record(nil, calgan, { [60] = "250" }, 1700000000)
    local mira = { guid = "Player-1-0000BBBB", fullName = "Mira Stonehand", class = "MAGE" }
    db = Sync.record(db, mira, { [60] = "3" }, 1700000500)
    assert.are.equal("Calgan Blackbeard", db.characters["Player-1-0000AAAA"].fullName)
    assert.are.equal("Mira Stonehand", db.characters["Player-1-0000BBBB"].fullName)
  end)

  it("keeps the previous Snapshot and Last Synced when no Statistic could be read", function()
    local db = Sync.record(nil, calgan, { [60] = "250" }, 1700000000)
    db = Sync.record(db, calgan, {}, 1700000900)
    assert.are.same({ [60] = "250" }, db.characters["Player-1-0000AAAA"].snapshot)
    assert.are.equal(1700000000, db.characters["Player-1-0000AAAA"].lastSynced)
  end)

  it("keeps the previous Snapshot and Last Synced when every value is --", function()
    local db = Sync.record(nil, calgan, { [60] = "250", [98] = "3" }, 1700000000)
    db = Sync.record(db, calgan, { [60] = "--", [98] = "--" }, 1700000900)
    assert.are.same({ [60] = "250", [98] = "3" }, db.characters["Player-1-0000AAAA"].snapshot)
    assert.are.equal(1700000000, db.characters["Player-1-0000AAAA"].lastSynced)
  end)

  it("records an unreadable Snapshot when there is no earlier one", function()
    local db = Sync.record(nil, calgan, {}, 1700000000)
    assert.are.same({
      fullName = "Calgan Blackbeard",
      ruleset = "PvE",
      class = "WARRIOR",
      lastSynced = 1700000000,
      snapshot = {},
    }, db.characters["Player-1-0000AAAA"])
  end)

  it("updates Full Name, Ruleset and class even when the Snapshot is unreadable", function()
    local db = Sync.record(nil, calgan, { [60] = "250" }, 1700000000)
    local renamed = { guid = "Player-1-0000AAAA", fullName = "Calgan Ironbeard", ruleset = "PvE", class = "PALADIN" }
    db = Sync.record(db, renamed, { [60] = "--" }, 1700000900)
    assert.are.same({
      fullName = "Calgan Ironbeard",
      ruleset = "PvE",
      class = "PALADIN",
      lastSynced = 1700000000,
      snapshot = { [60] = "250" },
    }, db.characters["Player-1-0000AAAA"])
  end)

  it("replaces the Snapshot when some values are -- and others are readable", function()
    local db = Sync.record(nil, calgan, { [60] = "250", [98] = "3" }, 1700000000)
    db = Sync.record(db, calgan, { [60] = "251", [98] = "--" }, 1700000900)
    assert.are.same({ [60] = "251", [98] = "--" }, db.characters["Player-1-0000AAAA"].snapshot)
    assert.are.equal(1700000900, db.characters["Player-1-0000AAAA"].lastSynced)
  end)
end)

describe("Sync.forget", function()
  local Sync = loadSync()
  local calgan = { guid = "Player-1-0000AAAA", fullName = "Calgan Blackbeard", ruleset = "PvE", class = "WARRIOR" }
  local mira = { guid = "Player-1-0000BBBB", fullName = "Mira Stonehand", ruleset = "PvE", class = "MAGE" }

  local function trackBoth()
    local db = Sync.record(nil, calgan, { [60] = "250" }, 1700000000)
    return Sync.record(db, mira, { [60] = "3" }, 1700000500)
  end

  it("removes the Tracked Character and its Snapshot, keeping the others", function()
    local db = Sync.forget(trackBoth(), mira.guid, calgan.guid)
    assert.is_nil(db.characters[mira.guid])
    assert.are.same({ [60] = "250" }, db.characters[calgan.guid].snapshot)
  end)

  it("never forgets the logged-in Character", function()
    local db = Sync.forget(trackBoth(), calgan.guid, calgan.guid)
    assert.are.same({ [60] = "250" }, db.characters[calgan.guid].snapshot)
    assert.are.same({ [60] = "3" }, db.characters[mira.guid].snapshot)
  end)

  it("tracks a forgotten Character anew when it Syncs again", function()
    local db = Sync.forget(trackBoth(), mira.guid, calgan.guid)
    db = Sync.record(db, mira, { [60] = "4" }, 1700009000)
    assert.are.same({
      fullName = "Mira Stonehand",
      ruleset = "PvE",
      class = "MAGE",
      lastSynced = 1700009000,
      snapshot = { [60] = "4" },
    }, db.characters[mira.guid])
  end)

  it("drops the forgotten Character from the dropdown and the Account Totals", function()
    local ns = addon.loadFile("Locale.lua", { Sync = Sync })
    local Characters = addon.loadFile("Characters.lua", ns).Characters
    local AccountTotals = addon.loadFile("AccountTotals.lua", addon.loadFile("Values.lua", ns)).AccountTotals
    local db = Sync.forget(trackBoth(), mira.guid, calgan.guid)

    local entries = Characters.dropdownEntries(db, calgan.guid, 1700010000)
    assert.are.equal(1, #entries)
    assert.are.equal(calgan.guid, entries[1].guid)
    local _, all = Characters.statisticValues(db, calgan.guid)
    assert.are.equal("250", AccountTotals.display(60, all))
  end)
end)
