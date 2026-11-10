local addon = require("addon")

local function loadRows()
  local ns = addon.loadFile("Locale.lua", {})
  addon.loadFile("Values.lua", ns)
  addon.loadFile("Roster.lua", ns)
  addon.loadFile("AccountStatistics.lua", ns)
  addon.loadFile("RowLayout.lua", ns)
  return addon.loadFile("Rows.lua", ns)
end

local CURRENT, OTHER = "Player-1-0000AAAA", "Player-1-0000BBBB"

describe("Rows.build", function()
  local ns = loadRows()
  local Rows, AccountStatistics = ns.Rows, ns.AccountStatistics

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

  it("gives Statistic rows the selected Character's value and the Account Total, and every row its layout", function()
    local statistics = AccountStatistics.new(db, CURRENT, liveValues)
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
    }, Rows.build(visible, statistics, OTHER))
  end)

  it("leaves the rows it is given unchanged", function()
    local statistics = AccountStatistics.new(db, CURRENT, liveValues)
    Rows.build(visible, statistics, OTHER)
    assert.are.same({ kind = "category", id = 130, name = "Character", depth = 0, expanded = true }, visible[1])
  end)

  it("marks every value missing when no Character is selected", function()
    local rows = Rows.build(visible, AccountStatistics.new({ characters = {} }, CURRENT, liveValues), nil)
    assert.are.same({ "?", "?", "?" }, { rows[2].value, rows[3].value, rows[5].value })
  end)
end)
