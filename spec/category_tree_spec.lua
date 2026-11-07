local addon = require("addon")

local function loadCategoryTree()
  return addon.loadFile("CategoryTree.lua", {}).CategoryTree
end

describe("CategoryTree.build", function()
  local CategoryTree = loadCategoryTree()

  it("nests Categories under their parents with their Statistics, in game order", function()
    local categories = {
      { id = 130, name = "Character", parentID = -1 },
      { id = 141, name = "Combat", parentID = -1 },
      { id = 131, name = "Wealth", parentID = 130 },
      { id = 145, name = "Consumables", parentID = 130 },
    }
    local statistics = {
      [130] = { { id = 60, name = "Total deaths" } },
      [131] = { { id = 328, name = "Total gold acquired" }, { id = 326, name = "Gold from quest rewards" } },
      [141] = { { id = 193, name = "Largest hit dealt" } },
    }

    assert.are.same({
      {
        id = 130, name = "Character",
        statistics = { { id = 60, name = "Total deaths" } },
        children = {
          {
            id = 131, name = "Wealth",
            statistics = { { id = 328, name = "Total gold acquired" }, { id = 326, name = "Gold from quest rewards" } },
            children = {},
          },
          { id = 145, name = "Consumables", statistics = {}, children = {} },
        },
      },
      { id = 141, name = "Combat", statistics = { { id = 193, name = "Largest hit dealt" } }, children = {} },
    }, CategoryTree.build(categories, statistics))
  end)

  it("puts a Category with an unknown parent at the root", function()
    local tree = CategoryTree.build({ { id = 152, name = "Dungeons & Raids", parentID = 999 } }, {})
    assert.are.same({ { id = 152, name = "Dungeons & Raids", statistics = {}, children = {} } }, tree)
  end)

  it("leaves out Statistics the default Statistics panel skips", function()
    local tree = CategoryTree.build({ { id = 130, name = "Character", parentID = -1 } }, {
      [130] = {
        { id = 60, name = "Total deaths", skip = false },
        { id = 61, name = "Hidden statistic", skip = true },
        { id = 98, name = "Quests completed" },
      },
    })
    assert.are.same({ {
      id = 130, name = "Character",
      statistics = { { id = 60, name = "Total deaths", skip = false }, { id = 98, name = "Quests completed" } },
      children = {},
    } }, tree)
  end)
end)

describe("CategoryTree.visibleRows", function()
  local CategoryTree = loadCategoryTree()

  local tree = CategoryTree.build({
    { id = 130, name = "Character", parentID = -1 },
    { id = 131, name = "Wealth", parentID = 130 },
    { id = 141, name = "Combat", parentID = -1 },
  }, {
    [130] = { { id = 60, name = "Total deaths" } },
    [131] = { { id = 328, name = "Total gold acquired" } },
    [141] = { { id = 193, name = "Largest hit dealt" } },
  })

  it("shows only the root Categories, collapsed, when nothing is expanded", function()
    assert.are.same({
      { kind = "category", id = 130, name = "Character", depth = 0, expanded = false },
      { kind = "category", id = 141, name = "Combat", depth = 0, expanded = false },
    }, CategoryTree.visibleRows(tree, {}))
  end)

  it("shows an expanded Category's own Statistics, then its child Categories, one level deeper", function()
    assert.are.same({
      { kind = "category", id = 130, name = "Character", depth = 0, expanded = true },
      { kind = "statistic", id = 60, name = "Total deaths", depth = 1 },
      { kind = "category", id = 131, name = "Wealth", depth = 1, expanded = false },
      { kind = "category", id = 141, name = "Combat", depth = 0, expanded = false },
    }, CategoryTree.visibleRows(tree, { [130] = true }))
  end)

  it("hides an expanded child Category while its parent is collapsed, and shows it again with the parent", function()
    local expanded = { [131] = true }
    assert.are.same({
      { kind = "category", id = 130, name = "Character", depth = 0, expanded = false },
      { kind = "category", id = 141, name = "Combat", depth = 0, expanded = false },
    }, CategoryTree.visibleRows(tree, expanded))

    expanded[130] = true
    assert.are.same({
      { kind = "category", id = 130, name = "Character", depth = 0, expanded = true },
      { kind = "statistic", id = 60, name = "Total deaths", depth = 1 },
      { kind = "category", id = 131, name = "Wealth", depth = 1, expanded = true },
      { kind = "statistic", id = 328, name = "Total gold acquired", depth = 2 },
      { kind = "category", id = 141, name = "Combat", depth = 0, expanded = false },
    }, CategoryTree.visibleRows(tree, expanded))
  end)
end)
