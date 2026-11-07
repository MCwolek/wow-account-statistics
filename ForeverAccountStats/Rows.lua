-- Pure rows of the Statistics window's list: each Statistic with the selected Character's value and the Account Total.
local _, ns = ...

local Rows = {}
ns.Rows = Rows

-- The list's rows from CategoryTree.visibleRows for `view`, { db, selectedGUID, currentGUID, liveValues }. Each
-- Statistic row gets `value`, the selected Character's value (Values.display), `total`, the Account Total
-- (AccountTotals.display) over every Tracked Character, and `odd`, which stripes the Statistics below each Category
-- header, starting odd. The logged-in Character (`currentGUID`) counts with `liveValues`, read just now, in place of
-- its saved Snapshot. Category rows are kept as they are.
function Rows.build(visibleRows, view)
  local byGUID, all = ns.Characters.statisticValues(view.db, view.currentGUID, view.liveValues)
  local selected = byGUID[view.selectedGUID] or {}
  local rows, odd = {}, true
  for _, row in ipairs(visibleRows) do
    if row.kind == "statistic" then
      rows[#rows + 1] = {
        kind = row.kind, id = row.id, name = row.name, depth = row.depth,
        value = ns.Values.display(selected[row.id]),
        total = ns.AccountTotals.display(row.id, all),
        odd = odd,
      }
      odd = not odd
    else
      rows[#rows + 1] = row
      odd = true
    end
  end
  return rows
end
