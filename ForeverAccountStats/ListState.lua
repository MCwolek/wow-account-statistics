-- Pure state of the Statistics window's list: which Categories are expanded, and the search.
local _, ns = ...
local CategoryTree = ns.CategoryTree

local ListState = {}
ns.ListState = ListState

-- The set { [categoryID] = true } of every Category in the Category tree `tree`, nested ones too, added to
-- `expanded` when given.
local function allExpanded(tree, expanded)
  expanded = expanded or {}
  for _, node in ipairs(tree) do
    expanded[node.id] = true
    allExpanded(node.children, expanded)
  end
  return expanded
end

-- A copy of `expanded`, the set { [categoryID] = true }, with the Category `categoryID` expanded when it was
-- collapsed and collapsed when it was expanded.
local function toggledCopy(expanded, categoryID)
  local result = {}
  for id in pairs(expanded) do
    result[id] = true
  end
  result[categoryID] = not expanded[categoryID] or nil
  return result
end

local function addRows(rows, nodes, expanded, depth)
  for _, node in ipairs(nodes) do
    local isExpanded = expanded[node.id] == true
    rows[#rows + 1] = { kind = "category", id = node.id, name = node.name, depth = depth, expanded = isExpanded }
    if isExpanded then
      for _, statistic in ipairs(node.statistics) do
        rows[#rows + 1] = { kind = "statistic", id = statistic.id, name = statistic.name, depth = depth + 1 }
      end
      addRows(rows, node.children, expanded, depth + 1)
    end
  end
end

-- The list of the whole tree, every Category expanded, nested ones too, with no search.
function ListState.new(tree)
  return { whole = { tree = tree, expanded = allExpanded(tree) } }
end

-- The list with the Category `categoryID` expanded when it was collapsed and collapsed when it was expanded.
-- A search keeps the whole tree's expanded Categories for when it is cleared.
function ListState.toggled(state, categoryID)
  local function toggledView(view)
    return { tree = view.tree, expanded = toggledCopy(view.expanded, categoryID) }
  end
  if state.search then
    return { whole = state.whole, search = toggledView(state.search) }
  end
  return { whole = toggledView(state.whole) }
end

-- The list for the search box's `text`: the search results of the text without the spaces around it, every Category
-- expanded, each time anew; the whole tree again, as it was expanded, when the text is empty or only spaces.
function ListState.searched(state, text)
  local term = string.match(text, "^%s*(.-)%s*$")
  if term == "" then
    return { whole = state.whole }
  end
  local results = CategoryTree.searchResults(state.whole.tree, term)
  return { whole = state.whole, search = { tree = results, expanded = allExpanded(results) } }
end

-- The rows the list shows, top to bottom: { kind = "category", id, name, depth, expanded } and
-- { kind = "statistic", id, name, depth }, roots at depth 0. An expanded Category shows its own Statistics, then its
-- child Categories; a collapsed one hides its whole subtree.
function ListState.visibleRows(state)
  local rows = {}
  local shown = state.search or state.whole
  addRows(rows, shown.tree, shown.expanded, 0)
  return rows
end
