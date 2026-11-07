-- Pure Category tree for the Statistics window: the game's Categories and Statistics as nested nodes.
local _, ns = ...

local CategoryTree = {}
ns.CategoryTree = CategoryTree

-- The Statistics of one Category the default Statistics panel shows: all but those marked `skip`.
local function shown(statistics)
  local result = {}
  for _, statistic in ipairs(statistics or {}) do
    if not statistic.skip then
      result[#result + 1] = statistic
    end
  end
  return result
end

-- The nodes that have something to show: a Statistic of their own or a child Category kept in turn.
local function withStatistics(nodes)
  local kept = {}
  for _, node in ipairs(nodes) do
    node.children = withStatistics(node.children)
    if #node.statistics > 0 or #node.children > 0 then
      kept[#kept + 1] = node
    end
  end
  return kept
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
      statistics = shown(statistics[category.id]),
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
  return withStatistics(roots)
end

-- Copies of the nodes holding a Statistic whose lowercased name contains `term`, each with only those Statistics and
-- the child Categories kept in turn.
local function matching(nodes, term)
  local kept = {}
  for _, node in ipairs(nodes) do
    local statistics = {}
    for _, statistic in ipairs(node.statistics) do
      if string.find(string.lower(statistic.name), term, 1, true) then
        statistics[#statistics + 1] = statistic
      end
    end
    local children = matching(node.children, term)
    if #statistics > 0 or #children > 0 then
      kept[#kept + 1] = { id = node.id, name = node.name, statistics = statistics, children = children }
    end
  end
  return kept
end

-- The tree cut down to the Statistics whose name contains `text`, ignoring case and spaces around it, and the
-- Categories above them; nil when `text` is empty or only spaces, which is no search at all. Category names are not
-- matched. The tree given is left unchanged.
function CategoryTree.filtered(tree, text)
  local term = string.match(text, "^%s*(.-)%s*$")
  if term == "" then
    return nil
  end
  return matching(tree, string.lower(term))
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
