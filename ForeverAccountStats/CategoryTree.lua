-- Pure Category tree for the Statistics window: the game's Categories and Statistics as nested nodes.
local _, ns = ...

local CategoryTree = {}
ns.CategoryTree = CategoryTree

-- Copies of the nodes that have something to show: each holds the Statistics `keep` picks of its own and the child
-- Categories kept in turn, and is left out when neither remains. The nodes given are left unchanged.
local function pruned(nodes, keep)
  local kept = {}
  for _, node in ipairs(nodes) do
    local statistics = {}
    for _, statistic in ipairs(node.statistics) do
      if keep(statistic) then
        statistics[#statistics + 1] = statistic
      end
    end
    local children = pruned(node.children, keep)
    if #statistics > 0 or #children > 0 then
      kept[#kept + 1] = { id = node.id, name = node.name, statistics = statistics, children = children }
    end
  end
  return kept
end

-- Whether the default Statistics panel shows the Statistic: all but those marked `skip`.
local function isShown(statistic)
  return not statistic.skip
end

-- Root nodes { id, name, statistics, children } from `categories`, an ordered list of { id, name, parentID },
-- and `statistics`, { [categoryID] = { { id, name, skip }, ... } }. A Category whose parent is -1 or unknown is a
-- root. Statistics marked `skip` are left out, as the default Statistics panel leaves them out, and so is a
-- Category with no Statistic to show anywhere below it. Game order is kept for Categories and Statistics alike.
function CategoryTree.build(categories, statistics)
  local nodes = {}
  for _, category in ipairs(categories) do
    nodes[category.id] = {
      id = category.id,
      name = category.name,
      statistics = statistics[category.id] or {},
      children = {},
    }
  end
  local roots = {}
  for _, category in ipairs(categories) do
    local parent = nodes[category.parentID]
    if parent then
      parent.children[#parent.children + 1] = nodes[category.id]
    else
      roots[#roots + 1] = nodes[category.id]
    end
  end
  return pruned(roots, isShown)
end

-- The tree cut down to the Statistics whose name contains `text`, ignoring case and spaces around it, and the
-- Categories above them; nil when `text` is empty or only spaces, which is no search at all. Category names are not
-- matched. The tree given is left unchanged.
function CategoryTree.filtered(tree, text)
  local term = string.match(text, "^%s*(.-)%s*$")
  if term == "" then
    return nil
  end
  term = string.lower(term)
  return pruned(tree, function(statistic)
    return string.find(string.lower(statistic.name), term, 1, true) ~= nil
  end)
end

local function expandAll(expanded, nodes)
  for _, node in ipairs(nodes) do
    expanded[node.id] = true
    expandAll(expanded, node.children)
  end
  return expanded
end

-- The set { [categoryID] = true } of every Category in the tree: for search results, which show expanded.
function CategoryTree.allExpanded(tree)
  return expandAll({}, tree)
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

-- The rows the list shows, top to bottom, for the tree and `expanded`, a set { [categoryID] = true }:
-- { kind = "category", id, name, depth, expanded } and { kind = "statistic", id, name, depth }, roots at depth 0.
-- An expanded Category shows its own Statistics, then its child Categories; a collapsed one hides its whole subtree.
function CategoryTree.visibleRows(tree, expanded)
  local rows = {}
  addRows(rows, tree, expanded, 0)
  return rows
end

-- A copy of `expanded`, the set { [categoryID] = true }, with the Category `categoryID` expanded when it was
-- collapsed and collapsed when it was expanded.
function CategoryTree.toggled(expanded, categoryID)
  local result = {}
  for id in pairs(expanded) do
    result[id] = true
  end
  result[categoryID] = not expanded[categoryID] or nil
  return result
end
