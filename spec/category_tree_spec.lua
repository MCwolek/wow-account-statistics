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
      [145] = { { id = 344, name = "Bandages used" } },
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
          { id = 145, name = "Consumables", statistics = { { id = 344, name = "Bandages used" } }, children = {} },
        },
      },
      { id = 141, name = "Combat", statistics = { { id = 193, name = "Largest hit dealt" } }, children = {} },
    }, CategoryTree.build(categories, statistics))
  end)

  it("puts a Category with an unknown parent at the root", function()
    local tree = CategoryTree.build({ { id = 152, name = "Dungeons & Raids", parentID = 999 } }, {
      [152] = { { id = 932, name = "Total 5-player dungeons entered" } },
    })
    assert.are.same({ {
      id = 152, name = "Dungeons & Raids",
      statistics = { { id = 932, name = "Total 5-player dungeons entered" } },
      children = {},
    } }, tree)
  end)

  it("leaves out a Category with no Statistic to show anywhere below it", function()
    local categories = {
      { id = 130, name = "Character", parentID = -1 },
      { id = 145, name = "Consumables", parentID = 130 },
      { id = 141, name = "Combat", parentID = -1 },
      { id = 142, name = "Hidden", parentID = 141 },
      { id = 143, name = "Empty", parentID = 142 },
    }
    local statistics = {
      [130] = { { id = 60, name = "Total deaths" } },
      [142] = { { id = 61, name = "Hidden statistic", skip = true } },
    }

    assert.are.same({
      { id = 130, name = "Character", statistics = { { id = 60, name = "Total deaths" } }, children = {} },
    }, CategoryTree.build(categories, statistics))
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

describe("CategoryTree.filtered", function()
  local CategoryTree = loadCategoryTree()

  local tree = CategoryTree.build({
    { id = 130, name = "Character", parentID = -1 },
    { id = 131, name = "Wealth", parentID = 130 },
    { id = 141, name = "Combat", parentID = -1 },
    { id = 122, name = "Deaths", parentID = -1 },
    { id = 123, name = "Arenas", parentID = 122 },
  }, {
    [130] = { { id = 60, name = "Total deaths" }, { id = 98, name = "Quests completed" } },
    [131] = { { id = 328, name = "Total gold acquired" } },
    [141] = { { id = 193, name = "Largest hit dealt" } },
    [122] = { { id = 107, name = "Deaths from drowning" } },
    [123] = { { id = 838, name = "Deaths in 2v2" } },
  })

  it("keeps only the Statistics whose name matches, whatever the case, with their Category path", function()
    assert.are.same({
      { id = 130, name = "Character", statistics = { { id = 60, name = "Total deaths" } }, children = {} },
      {
        id = 122, name = "Deaths",
        statistics = { { id = 107, name = "Deaths from drowning" } },
        children = {
          { id = 123, name = "Arenas", statistics = { { id = 838, name = "Deaths in 2v2" } }, children = {} },
        },
      },
    }, CategoryTree.filtered(tree, "DEATH"))
  end)

  it("ignores spaces before and after the text", function()
    assert.are.same(CategoryTree.filtered(tree, "total deaths"), CategoryTree.filtered(tree, "  total deaths "))
    assert.are.equal(1, #CategoryTree.filtered(tree, " total deaths "))
  end)

  it("does not match Category names", function()
    assert.are.same({}, CategoryTree.filtered(tree, "wealth"))
  end)

  it("matches the text as it is, not as a pattern", function()
    assert.are.same({}, CategoryTree.filtered(tree, "d."))
    assert.are.same({ {
      id = 122, name = "Deaths", statistics = {},
      children = {
        { id = 123, name = "Arenas", statistics = { { id = 838, name = "Deaths in 2v2" } }, children = {} },
      },
    } }, CategoryTree.filtered(tree, "2v2"))
  end)

  it("leaves the tree it was given unchanged", function()
    local function copy(value)
      if type(value) ~= "table" then
        return value
      end
      local result = {}
      for key, item in pairs(value) do
        result[key] = copy(item)
      end
      return result
    end
    local before = copy(tree)
    CategoryTree.filtered(tree, "death")
    assert.are.same(before, tree)
  end)

  it("is no search at all when the text is empty or only spaces", function()
    assert.is_nil(CategoryTree.filtered(tree, ""))
    assert.is_nil(CategoryTree.filtered(tree, "   "))
  end)
end)

describe("CategoryTree.allExpanded", function()
  local CategoryTree = loadCategoryTree()

  it("expands every Category of the tree, so search results show with their Category path", function()
    local tree = CategoryTree.build({
      { id = 130, name = "Character", parentID = -1 },
      { id = 131, name = "Wealth", parentID = 130 },
      { id = 141, name = "Combat", parentID = -1 },
    }, {
      [130] = { { id = 60, name = "Total deaths" } },
      [131] = { { id = 328, name = "Total gold acquired" } },
      [141] = { { id = 193, name = "Largest hit dealt" } },
    })
    local matches = CategoryTree.filtered(tree, "gold")

    assert.are.same({
      { kind = "category", id = 130, name = "Character", depth = 0, expanded = true },
      { kind = "category", id = 131, name = "Wealth", depth = 1, expanded = true },
      { kind = "statistic", id = 328, name = "Total gold acquired", depth = 2 },
    }, CategoryTree.visibleRows(matches, CategoryTree.allExpanded(matches)))
  end)
end)

describe("CategoryTree.toggled", function()
  local CategoryTree = loadCategoryTree()

  it("expands a collapsed Category and keeps the others as they are", function()
    assert.are.same({ [130] = true, [131] = true }, CategoryTree.toggled({ [131] = true }, 130))
  end)

  it("collapses an expanded Category", function()
    assert.are.same({ [131] = true }, CategoryTree.toggled({ [130] = true, [131] = true }, 130))
  end)

  it("leaves the set it was given unchanged", function()
    local expanded = { [131] = true }
    CategoryTree.toggled(expanded, 130)
    assert.are.same({ [131] = true }, expanded)
  end)
end)
