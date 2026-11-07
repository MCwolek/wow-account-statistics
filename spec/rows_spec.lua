local addon = require("addon")

local function loadCells()
  local ns = addon.loadFile("Locale.lua", {})
  addon.loadFile("Values.lua", ns)
  addon.loadFile("AccountTotals.lua", ns)
  return addon.loadFile("Cells.lua", ns).Cells
end

local CURRENT, OTHER = "Player-1-0000AAAA", "Player-1-0000BBBB"

describe("Cells.statistic", function()
  local Cells = loadCells()

  local db = {
    characters = {
      [CURRENT] = { fullName = "Calgan Blackbeard", snapshot = { [60] = "2", [98] = "27" } },
      [OTHER] = { fullName = "Mira Stonehand", snapshot = { [60] = "3", [98] = "84" } },
    },
  }
  local live = { [60] = "5", [98] = "30" }

  it("shows another Character's value from its Snapshot and counts the logged-in Character's live value", function()
    assert.are.same({ value = "3", total = "8" }, Cells.statistic(db, 60, OTHER, CURRENT, live))
  end)

  it("shows the logged-in Character's live value", function()
    assert.are.same({ value = "30", total = "114" }, Cells.statistic(db, 98, CURRENT, CURRENT, live))
  end)
end)

describe("Cells.rows", function()
  local Cells = loadCells()

  local db = {
    characters = {
      [CURRENT] = { fullName = "Calgan Blackbeard", snapshot = { [60] = "2", [98] = "27", [328] = "10" } },
      [OTHER] = { fullName = "Mira Stonehand", snapshot = { [60] = "3", [98] = "84", [328] = "5" } },
    },
  }
  local live = { [60] = "5", [98] = "30", [328] = "12" }

  it("gives Statistic rows the selected Character's value, the Account Total and stripes from each Category", function()
    local visible = {
      { kind = "category", id = 130, name = "Character", depth = 0, expanded = true },
      { kind = "statistic", id = 60, name = "Total deaths", depth = 1 },
      { kind = "statistic", id = 98, name = "Quests completed", depth = 1 },
      { kind = "category", id = 131, name = "Wealth", depth = 1, expanded = true },
      { kind = "statistic", id = 328, name = "Total gold acquired", depth = 2 },
    }
    assert.are.same({
      { kind = "category", id = 130, name = "Character", depth = 0, expanded = true },
      { kind = "statistic", id = 60, name = "Total deaths", depth = 1, value = "3", total = "8", odd = true },
      { kind = "statistic", id = 98, name = "Quests completed", depth = 1, value = "84", total = "114", odd = false },
      { kind = "category", id = 131, name = "Wealth", depth = 1, expanded = true },
      { kind = "statistic", id = 328, name = "Total gold acquired", depth = 2, value = "5", total = "17", odd = true },
    }, Cells.rows(visible, db, OTHER, CURRENT, live))
  end)
end)
