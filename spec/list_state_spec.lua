local addon = require("addon")

local function loadListState()
  local ns = addon.loadFile("CategoryTree.lua", {})
  return addon.loadFile("ListState.lua", ns).ListState, ns.CategoryTree
end

describe("ListState", function()
  local ListState, CategoryTree = loadListState()

  local tree = CategoryTree.build({
    { id = 130, name = "Character", parentID = -1 },
    { id = 131, name = "Wealth", parentID = 130 },
    { id = 141, name = "Combat", parentID = -1 },
  }, {
    [130] = { { id = 60, name = "Total deaths" } },
    [131] = { { id = 328, name = "Total gold acquired" } },
    [141] = { { id = 193, name = "Largest hit dealt" } },
  })

  it("starts with the whole tree expanded, nested Categories too", function()
    assert.are.same({
      { kind = "category", id = 130, name = "Character", depth = 0, expanded = true },
      { kind = "statistic", id = 60, name = "Total deaths", depth = 1 },
      { kind = "category", id = 131, name = "Wealth", depth = 1, expanded = true },
      { kind = "statistic", id = 328, name = "Total gold acquired", depth = 2 },
      { kind = "category", id = 141, name = "Combat", depth = 0, expanded = true },
      { kind = "statistic", id = 193, name = "Largest hit dealt", depth = 1 },
    }, ListState.visibleRows(ListState.new(tree)))
  end)

  it("collapses a Category toggled once and expands it again when toggled twice", function()
    local state = ListState.toggled(ListState.new(tree), 130)
    assert.are.same({
      { kind = "category", id = 130, name = "Character", depth = 0, expanded = false },
      { kind = "category", id = 141, name = "Combat", depth = 0, expanded = true },
      { kind = "statistic", id = 193, name = "Largest hit dealt", depth = 1 },
    }, ListState.visibleRows(state))

    assert.are.same(ListState.visibleRows(ListState.new(tree)), ListState.visibleRows(ListState.toggled(state, 130)))
  end)

  it("keeps a nested Category as it was while its parent is collapsed", function()
    local state = ListState.toggled(ListState.toggled(ListState.new(tree), 131), 130)
    assert.are.same({
      { kind = "category", id = 130, name = "Character", depth = 0, expanded = false },
      { kind = "category", id = 141, name = "Combat", depth = 0, expanded = true },
      { kind = "statistic", id = 193, name = "Largest hit dealt", depth = 1 },
    }, ListState.visibleRows(state))

    assert.are.same({
      { kind = "category", id = 130, name = "Character", depth = 0, expanded = true },
      { kind = "statistic", id = 60, name = "Total deaths", depth = 1 },
      { kind = "category", id = 131, name = "Wealth", depth = 1, expanded = false },
      { kind = "category", id = 141, name = "Combat", depth = 0, expanded = true },
      { kind = "statistic", id = 193, name = "Largest hit dealt", depth = 1 },
    }, ListState.visibleRows(ListState.toggled(state, 130)))
  end)

  it("leaves the list it was given unchanged", function()
    local state = ListState.new(tree)
    ListState.toggled(state, 130)
    ListState.searched(state, "gold")
    assert.are.same(ListState.visibleRows(ListState.new(tree)), ListState.visibleRows(state))
  end)

  it("leaves the list it was given unchanged when toggling during a search", function()
    local state = ListState.searched(ListState.new(tree), "gold")
    ListState.toggled(state, 131)
    assert.are.same(
      ListState.visibleRows(ListState.searched(ListState.new(tree), "gold")),
      ListState.visibleRows(state)
    )
    assert.are.same(ListState.visibleRows(ListState.new(tree)), ListState.visibleRows(ListState.searched(state, "")))
  end)

  it("shows the search results with every Category expanded", function()
    assert.are.same({
      { kind = "category", id = 130, name = "Character", depth = 0, expanded = true },
      { kind = "category", id = 131, name = "Wealth", depth = 1, expanded = true },
      { kind = "statistic", id = 328, name = "Total gold acquired", depth = 2 },
    }, ListState.visibleRows(ListState.searched(ListState.new(tree), "Gold")))
  end)

  it("toggles a Category in the search results without touching the whole tree's expanded Categories", function()
    local state = ListState.searched(ListState.toggled(ListState.new(tree), 130), "gold")
    state = ListState.toggled(state, 131)
    assert.are.same({
      { kind = "category", id = 130, name = "Character", depth = 0, expanded = true },
      { kind = "category", id = 131, name = "Wealth", depth = 1, expanded = false },
    }, ListState.visibleRows(state))

    assert.are.same({
      { kind = "category", id = 130, name = "Character", depth = 0, expanded = false },
      { kind = "category", id = 141, name = "Combat", depth = 0, expanded = true },
      { kind = "statistic", id = 193, name = "Largest hit dealt", depth = 1 },
    }, ListState.visibleRows(ListState.searched(state, "")))
  end)

  it("treats text of only spaces as no search", function()
    local state = ListState.toggled(ListState.new(tree), 141)
    assert.are.same(ListState.visibleRows(state), ListState.visibleRows(ListState.searched(state, "   ")))
  end)

  it("ignores spaces around the text", function()
    local state = ListState.new(tree)
    assert.are.same(
      ListState.visibleRows(ListState.searched(state, "gold")),
      ListState.visibleRows(ListState.searched(state, "  gold "))
    )
  end)

  it("expands every Category of the search results again on each new text", function()
    local state = ListState.toggled(ListState.searched(ListState.new(tree), "t"), 130)
    assert.are.same({
      { kind = "category", id = 130, name = "Character", depth = 0, expanded = true },
      { kind = "statistic", id = 60, name = "Total deaths", depth = 1 },
      { kind = "category", id = 131, name = "Wealth", depth = 1, expanded = true },
      { kind = "statistic", id = 328, name = "Total gold acquired", depth = 2 },
    }, ListState.visibleRows(ListState.searched(state, "to")))
  end)
end)
