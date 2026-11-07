-- Pure state of the Statistics window's list: which Categories are expanded, and the search.
local _, ns = ...
local CategoryTree = ns.CategoryTree

local ListState = {}
ns.ListState = ListState

-- The list of the whole tree, every Category collapsed, with no search.
function ListState.new(tree)
  return { whole = { tree = tree, expanded = {} } }
end

-- The list with the Category `categoryID` expanded when it was collapsed and collapsed when it was expanded.
-- A search keeps the whole tree's expanded Categories for when it is cleared.
function ListState.toggled(state, categoryID)
  local function toggledIn(view)
    return { tree = view.tree, expanded = CategoryTree.toggled(view.expanded, categoryID) }
  end
  if state.search then
    return { whole = state.whole, search = toggledIn(state.search) }
  end
  return { whole = toggledIn(state.whole) }
end

-- The list for the search box's `text`: the search results of the text without the spaces around it, every Category
-- expanded, each time anew; the whole tree again, as it was expanded, when the text is empty or only spaces.
function ListState.searched(state, text)
  local term = string.match(text, "^%s*(.-)%s*$")
  if term == "" then
    return { whole = state.whole }
  end
  local results = CategoryTree.searchResults(state.whole.tree, term)
  return { whole = state.whole, search = { tree = results, expanded = CategoryTree.allExpanded(results) } }
end

-- The rows the list shows, as CategoryTree.visibleRows gives them.
function ListState.visibleRows(state)
  local shown = state.search or state.whole
  return CategoryTree.visibleRows(shown.tree, shown.expanded)
end
