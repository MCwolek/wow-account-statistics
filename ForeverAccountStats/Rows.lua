-- Pure rows of the Statistics window's list: each Statistic with the selected Character's value and the Account Total,
-- and every row with its layout.
local _, ns = ...

local Rows = {}
ns.Rows = Rows

-- The list's rows from CategoryTree.visibleRows for `view`, { db, selectedGUID, currentGUID, liveValues }. Each
-- Statistic row gets `value`, the selected Character's value (Values.display), `total`, the Account Total
-- (AccountTotals.display) over every Tracked Character. The logged-in Character (`currentGUID`) counts with
-- `liveValues`, read just now, in place of its saved Snapshot. Every row gets `layout`, its RowLayout. The rows given
-- are left unchanged.
function Rows.build(visibleRows, view)
  local byGUID, all = ns.Characters.statisticValues(view.db, view.currentGUID, view.liveValues)
  local selected = byGUID[view.selectedGUID] or {}
  local rows = {}
  for _, row in ipairs(visibleRows) do
    local built = { kind = row.kind, id = row.id, name = row.name, depth = row.depth, layout = ns.RowLayout.of(row) }
    if row.kind == "statistic" then
      built.value = ns.Values.display(selected[row.id])
      built.total = ns.AccountTotals.display(row.id, all)
    else
      built.expanded = row.expanded
    end
    rows[#rows + 1] = built
  end
  return rows
end
