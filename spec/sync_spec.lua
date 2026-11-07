local addon = require("addon")

local function loadSync()
  local ns = addon.loadFile("Locale.lua", {})
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
  local calgan = { guid = "Player-1-0000AAAA", fullName = "Calgan Blackbeard", class = "WARRIOR" }

  it("stores the Character under its GUID with Full Name, class, Last Synced and Snapshot", function()
    local db = Sync.record(nil, calgan, { [60] = "250" }, 1700000000)
    assert.are.same({
      fullName = "Calgan Blackbeard",
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
end)
