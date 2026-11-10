-- Pure rows of the Statistics window's list: each Statistic with the selected Character's value and the Account Total,
-- and how each row is laid out.
local _, ns = ...

local Rows = {}
ns.Rows = Rows

-- The list's rows from CategoryTree.visibleRows for `view`, { db, selectedGUID, currentGUID, liveValues }. Each
-- Statistic row gets `value`, the selected Character's value (Values.display), `total`, the Account Total
-- (AccountTotals.display) over every Tracked Character. The logged-in Character (`currentGUID`) counts with
-- `liveValues`, read just now, in place of its saved Snapshot. Category rows are kept as they are.
function Rows.build(visibleRows, view)
  local byGUID, all = ns.Characters.statisticValues(view.db, view.currentGUID, view.liveValues)
  local selected = byGUID[view.selectedGUID] or {}
  local rows = {}
  for _, row in ipairs(visibleRows) do
    if row.kind == "statistic" then
      rows[#rows + 1] = {
        kind = row.kind, id = row.id, name = row.name, depth = row.depth,
        value = ns.Values.display(selected[row.id]),
        total = ns.AccountTotals.display(row.id, all),
      }
    else
      rows[#rows + 1] = row
    end
  end
  return rows
end

-- Row heights by look, and the indent per depth, as the game's Statistics tab has them.
local HEIGHTS = { category = 26, statistic = 24, nestedCategory = 22 }
local INDENT = 20

-- How the list lays out `row`, one of the rows above: { look, height, indent }. The look is "category" for a
-- top-level Category, on its bar with the +/- on the right, "nestedCategory" for one inside another, with the
-- open/closed icon on the left, or "statistic". Each depth indents the row by 20.
function Rows.layout(row)
  local look
  if row.kind == "statistic" then
    look = "statistic"
  elseif row.depth > 0 then
    look = "nestedCategory"
  else
    look = "category"
  end
  return { look = look, height = HEIGHTS[look], indent = row.depth * INDENT }
end
