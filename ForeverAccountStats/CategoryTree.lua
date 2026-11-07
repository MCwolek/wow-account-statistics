-- Pure Category tree for the Statistics window: the game's Categories and Statistics as nested nodes.
local _, ns = ...

local CategoryTree = {}
ns.CategoryTree = CategoryTree

-- Root nodes { id, name, statistics, children } from `categories`, an ordered list of { id, name, parentID },
-- and `statistics`, { [categoryID] = { { id, name }, ... } }. A Category whose parent is -1 or unknown is a root.
-- Game order is kept for Categories and Statistics alike.
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
  return roots
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
