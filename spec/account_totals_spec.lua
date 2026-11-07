local addon = require("addon")

local function loadAccountTotals()
  local ns = addon.loadFile("Locale.lua", {})
  addon.loadFile("Values.lua", ns)
  return addon.loadFile("AccountTotals.lua", ns).AccountTotals
end

-- Values from real Snapshots of Schalgan Blackbeard and Keram (real-looking strings, single backslashes).
local blackbeard = {
  [60] = "--",
  [98] = "27",
  [107] = "468",
  [326] = "7|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t 27|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t",
}
local keram = {
  [60] = "3",
  [98] = "84",
  [107] = "514",
  [326] = "63|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t 10|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t",
}

describe("AccountTotals.display", function()
  local AccountTotals = loadAccountTotals()

  it("shows a money total with coin icons like the default UI", function()
    assert.are.equal(
      "70|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t 37|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t",
      AccountTotals.display(326, { blackbeard, keram })
    )
  end)

  it("shows a number total as plain digits", function()
    assert.are.equal("982", AccountTotals.display(107, { blackbeard, keram }))
  end)

  it("shows — when there is no Account Total", function()
    assert.are.equal("—", AccountTotals.display(1336, { { [1336] = "62 (Beasts)" } }))
    assert.are.equal("—", AccountTotals.display(95, { { [95] = "27" } }))
  end)

  it("shows -- when the Statistic never happened on any Character", function()
    assert.are.equal("--", AccountTotals.display(60, { blackbeard }))
  end)

  it("shows ? when no Character's Snapshot has the Statistic", function()
    assert.are.equal("?", AccountTotals.display(926, { blackbeard, keram }))
  end)
end)

describe("AccountTotals.compute", function()
  local AccountTotals = loadAccountTotals()

  it("sums a Statistic across Tracked Characters", function()
    assert.are.same({ kind = "number", amount = 111 }, AccountTotals.compute(98, { blackbeard, keram }))
  end)

  it("counts -- as 0", function()
    assert.are.same({ kind = "number", amount = 3 }, AccountTotals.compute(60, { blackbeard, keram }))
  end)

  it("sums money in copper", function()
    assert.are.same({ kind = "money", amount = 7037 }, AccountTotals.compute(326, { blackbeard, keram }))
  end)

  it("keeps money a money total when some Characters read --", function()
    local spent = { [331] = "--" }
    local sold = {
      [331] = "2|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t 9|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t",
    }
    assert.are.same({ kind = "money", amount = 209 }, AccountTotals.compute(331, { spent, sold, spent }))
  end)

  it("leaves out a Character whose Snapshot lacks the Statistic", function()
    local older = { [98] = "12" }
    assert.are.same({ kind = "number", amount = 982 }, AccountTotals.compute(107, { blackbeard, older, keram }))
  end)

  it("is missing when no Character's Snapshot has the Statistic", function()
    -- e.g. "Most Horde factions at Exalted" on an Account of Alliance Characters only.
    assert.are.same({ kind = "missing" }, AccountTotals.compute(926, { blackbeard, keram }))
    assert.are.same({ kind = "missing" }, AccountTotals.compute(98, {}))
  end)

  it("has no Account Total for a Text Statistic", function()
    local beasts = { [1336] = "62 (Beasts)" }
    local humanoid = { [1336] = "281 (Humanoid)" }
    local none = { [1336] = "--" }
    assert.is_nil(AccountTotals.compute(1336, { beasts, humanoid }))
    assert.is_nil(AccountTotals.compute(1336, { none, humanoid, {} }))
  end)

  it("has no Account Total for an Average Statistic", function()
    local first = {
      [95] = "27",
      [753] = "14|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t 56|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t",
    }
    local second = {
      [95] = "84",
      [753] = "1|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t 64|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t "
        .. "39|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t",
    }
    assert.is_nil(AccountTotals.compute(95, { first, second }))
    assert.is_nil(AccountTotals.compute(753, { first, second }))
  end)

  it("takes the highest value of a Peak Statistic", function()
    -- 193 Largest hit dealt
    local total = AccountTotals.compute(193, { { [193] = "87" }, { [193] = "54" } })
    assert.are.same({ kind = "number", amount = 87 }, total)
  end)

  it("takes the highest money of a Peak Statistic", function()
    -- 334 Most gold ever owned
    local poorer = {
      [334] = "11|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t 46|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t",
    }
    local richer = {
      [334] = "1|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t 30|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t "
        .. "39|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t",
    }
    assert.are.same({ kind = "money", amount = 13039 }, AccountTotals.compute(334, { poorer, richer }))
  end)

  it("counts -- as 0 and leaves out missing values for a Peak Statistic", function()
    -- 1466 Most Alliance factions at Exalted is missing from Horde Characters' Snapshots.
    local horde = { [926] = "1" }
    local alliance = { [926] = "--", [1466] = "--" }
    assert.are.same({ kind = "never", amount = 0 }, AccountTotals.compute(1466, { horde, alliance }))
    assert.are.same({ kind = "number", amount = 1 }, AccountTotals.compute(926, { alliance, horde }))
    assert.are.same({ kind = "missing" }, AccountTotals.compute(1466, { horde }))
  end)

  it("treats every hand-picked Peak Statistic as a Peak", function()
    local peaks = {
      189, 193, 281, 331, 332, 334, 338, 339, 377, 378, 527, 529, 829, 926, 931, 1337, 1466,
      1519, 1524, 1527, 1532, 1535, 1536, 1537, 1538, 1539, 1541, 1542, 1544,
    }
    for _, id in ipairs(peaks) do
      local total = AccountTotals.compute(id, { { [id] = "5" }, { [id] = "7" } })
      assert.are.same({ kind = "number", amount = 7 }, total, "Statistic " .. id)
    end
  end)

  it("still sums Statistics that look like Peaks but count across Characters", function()
    -- 1199 Professions learned, 927 Equipped epic items in item slots
    for _, id in ipairs({ 1199, 927 }) do
      local total = AccountTotals.compute(id, { { [id] = "5" }, { [id] = "7" } })
      assert.are.same({ kind = "number", amount = 12 }, total, "Statistic " .. id)
    end
  end)

  it("is never happened when every Character reads --", function()
    assert.are.same({ kind = "never", amount = 0 }, AccountTotals.compute(60, { blackbeard, blackbeard }))
  end)
end)
