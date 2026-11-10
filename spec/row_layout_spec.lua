local addon = require("addon")

describe("RowLayout.of", function()
  local RowLayout = addon.loadFile("RowLayout.lua", {}).RowLayout

  it("lays a top-level Category out as the game's Statistics tab does", function()
    local row = { kind = "category", id = 130, name = "Character", depth = 0, expanded = true }
    assert.are.same({ look = "category", height = 26, indent = 0 }, RowLayout.of(row))
  end)

  it("indents a Statistic 20 for each Category it sits in", function()
    local row = { kind = "statistic", id = 328, name = "Total gold acquired", depth = 2, value = "5", total = "17" }
    assert.are.same({ look = "statistic", height = 24, indent = 40 }, RowLayout.of(row))
  end)

  it("lays a nested Category out smaller, without the bar, indented like a Statistic", function()
    local row = { kind = "category", id = 131, name = "Wealth", depth = 1, expanded = false }
    assert.are.same({ look = "nestedCategory", height = 22, indent = 20 }, RowLayout.of(row))
  end)
end)
