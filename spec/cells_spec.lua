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
