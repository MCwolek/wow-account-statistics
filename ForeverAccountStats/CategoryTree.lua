-- Pure Category tree for the Statistics window: the game's Categories and Statistics as nested nodes.
local _, ns = ...

local CategoryTree = {}
ns.CategoryTree = CategoryTree

-- Copies of the nodes that have something to show: each holds the Statistics `keep` picks of its own and the child
-- Categories kept in turn, and is left out when neither remains. A node `keepWhole` picks, when given, is kept as it
-- is. The nodes given are left unchanged.
local function pruned(nodes, keep, keepWhole)
  local kept = {}
  for _, node in ipairs(nodes) do
    if keepWhole and keepWhole(node) then
      kept[#kept + 1] = node
    else
      local statistics = {}
      for _, statistic in ipairs(node.statistics) do
        if keep(statistic) then
          statistics[#statistics + 1] = statistic
        end
      end
      local children = pruned(node.children, keep, keepWhole)
      if #statistics > 0 or #children > 0 then
        kept[#kept + 1] = { id = node.id, name = node.name, statistics = statistics, children = children }
      end
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

-- The search results for `term`: the tree cut down to the Categories whose name contains it, ignoring case, each
-- kept whole, and the Statistics whose name contains it, each with the Categories above it. The tree given is left
-- unchanged.
function CategoryTree.searchResults(tree, term)
  local lowered = string.lower(term)
  local function contains(item)
    return string.find(string.lower(item.name), lowered, 1, true) ~= nil
  end
  return pruned(tree, contains, contains)
end
