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

describe("CategoryTree.searchResults", function()
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
    }, CategoryTree.searchResults(tree, "DEATH"))
  end)

  it("keeps the whole of a Category whose name matches, whatever the case, with its Category path", function()
    assert.are.same({ {
      id = 130, name = "Character", statistics = {},
      children = {
        { id = 131, name = "Wealth", statistics = { { id = 328, name = "Total gold acquired" } }, children = {} },
      },
    } }, CategoryTree.searchResults(tree, "WEAL"))
  end)

  it("keeps the child Categories of a Category whose name matches", function()
    assert.are.same({ {
      id = 130, name = "Character",
      statistics = { { id = 60, name = "Total deaths" }, { id = 98, name = "Quests completed" } },
      children = {
        { id = 131, name = "Wealth", statistics = { { id = 328, name = "Total gold acquired" } }, children = {} },
      },
    } }, CategoryTree.searchResults(tree, "charac"))
  end)

  it("searches for the text as it is, not as a pattern", function()
    assert.are.same({}, CategoryTree.searchResults(tree, "d."))
    assert.are.same({ {
      id = 122, name = "Deaths", statistics = {},
      children = {
        { id = 123, name = "Arenas", statistics = { { id = 838, name = "Deaths in 2v2" } }, children = {} },
      },
    } }, CategoryTree.searchResults(tree, "2v2"))
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
    CategoryTree.searchResults(tree, "death")
    assert.are.same(before, tree)
  end)
end)
