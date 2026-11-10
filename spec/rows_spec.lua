local addon = require("addon")

local function loadRows()
  local ns = addon.loadFile("Locale.lua", {})
  addon.loadFile("Values.lua", ns)
  addon.loadFile("AccountTotals.lua", ns)
  addon.loadFile("Characters.lua", ns)
  addon.loadFile("RowLayout.lua", ns)
  return addon.loadFile("Rows.lua", ns).Rows
end

local CURRENT, OTHER = "Player-1-0000AAAA", "Player-1-0000BBBB"

describe("Rows.build", function()
  local Rows = loadRows()

  local db = {
    characters = {
      [CURRENT] = { fullName = "Calgan Blackbeard", snapshot = { [60] = "2", [98] = "27", [328] = "10" } },
      [OTHER] = { fullName = "Mira Stonehand", snapshot = { [60] = "3", [98] = "84", [328] = "5" } },
    },
  }
  local liveValues = { [60] = "5", [98] = "30", [328] = "12" }

  local visible = {
    { kind = "category", id = 130, name = "Character", depth = 0, expanded = true },
    { kind = "statistic", id = 60, name = "Total deaths", depth = 1 },
    { kind = "statistic", id = 98, name = "Quests completed", depth = 1 },
    { kind = "category", id = 131, name = "Wealth", depth = 1, expanded = true },
    { kind = "statistic", id = 328, name = "Total gold acquired", depth = 2 },
  }

  it("gives Statistic rows another Character's saved value and the Account Total with the logged-in Character's "
    .. "live value, and every row its layout", function()
    local view = { db = db, selectedGUID = OTHER, currentGUID = CURRENT, liveValues = liveValues }
    local category = { look = "category", height = 26, indent = 0 }
    local statistic = { look = "statistic", height = 24, indent = 20 }
    assert.are.same({
      { kind = "category", id = 130, name = "Character", depth = 0, expanded = true, layout = category },
      { kind = "statistic", id = 60, name = "Total deaths", depth = 1, value = "3", total = "8", layout = statistic },
      { kind = "statistic", id = 98, name = "Quests completed", depth = 1, value = "84", total = "114",
        layout = statistic },
      { kind = "category", id = 131, name = "Wealth", depth = 1, expanded = true,
        layout = { look = "nestedCategory", height = 22, indent = 20 } },
      { kind = "statistic", id = 328, name = "Total gold acquired", depth = 2, value = "5", total = "17",
        layout = { look = "statistic", height = 24, indent = 40 } },
    }, Rows.build(visible, view))
  end)

  it("leaves the rows it is given unchanged", function()
    local view = { db = db, selectedGUID = OTHER, currentGUID = CURRENT, liveValues = liveValues }
    Rows.build(visible, view)
    assert.are.same({ kind = "category", id = 130, name = "Character", depth = 0, expanded = true }, visible[1])
  end)

  it("shows the logged-in Character's live values", function()
    local view = { db = db, selectedGUID = CURRENT, currentGUID = CURRENT, liveValues = liveValues }
    local rows = Rows.build(visible, view)
    assert.are.same({ "5", "30", "12" }, { rows[2].value, rows[3].value, rows[5].value })
  end)

  it("marks every value missing when no Character is selected", function()
    local view = { db = { characters = {} }, currentGUID = CURRENT, liveValues = liveValues }
    local rows = Rows.build(visible, view)
    assert.are.same({ "?", "?", "?" }, { rows[2].value, rows[3].value, rows[5].value })
  end)
end)
