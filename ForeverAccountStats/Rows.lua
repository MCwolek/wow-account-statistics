-- Pure rows of the Statistics window's list: each Statistic with the selected Character's value and the Account Total,
-- and every row with its layout.
local _, ns = ...

local Rows = {}
ns.Rows = Rows

-- The list's rows from CategoryTree.visibleRows, read from `statistics` (an AccountStatistics). Each Statistic row
-- gets `value`, the value of the Character `selectedGUID`, and `total`, the Account Total. Every row gets `layout`,
-- its RowLayout. The rows given are left unchanged.
function Rows.build(visibleRows, statistics, selectedGUID)
  local rows = {}
  for _, row in ipairs(visibleRows) do
    local built = { kind = row.kind, id = row.id, name = row.name, depth = row.depth, layout = ns.RowLayout.of(row) }
    if row.kind == "statistic" then
      built.value = statistics:value(selectedGUID, row.id)
      built.total = statistics:accountTotal(row.id)
    else
      built.expanded = row.expanded
    end
    rows[#rows + 1] = built
  end
  return rows
end
