-- Pure cells of the Statistics window's rows: the selected Character's value and the Account Total.
local _, ns = ...

local Cells = {}
ns.Cells = Cells

-- Cells of one Statistic row, { value, total }: the selected Character's value (Values.display) and the Account
-- Total (AccountTotals.display) over every Tracked Character. The logged-in Character (`currentGUID`) counts with
-- `liveSnapshot`, its values read just now, in place of its saved Snapshot.
function Cells.statistic(db, statisticID, selectedGUID, currentGUID, liveSnapshot)
  local snapshots, selected = {}, nil
  for guid, character in pairs(db.characters) do
    local snapshot = guid == currentGUID and liveSnapshot or character.snapshot or {}
    snapshots[#snapshots + 1] = snapshot
    if guid == selectedGUID then
      selected = snapshot
    end
  end
  return {
    value = ns.Values.display(selected[statisticID]),
    total = ns.AccountTotals.display(statisticID, snapshots),
  }
end

-- The list's rows from CategoryTree.visibleRows, each Statistic row completed with its cells (`value`, `total`, as
-- Cells.statistic gives them) and `odd`, which stripes the Statistics below each Category header, starting odd.
-- Category rows are kept as they are.
function Cells.rows(visibleRows, db, selectedGUID, currentGUID, liveSnapshot)
  local rows, odd = {}, true
  for _, row in ipairs(visibleRows) do
    if row.kind == "statistic" then
      local cells = Cells.statistic(db, row.id, selectedGUID, currentGUID, liveSnapshot)
      rows[#rows + 1] = {
        kind = row.kind, id = row.id, name = row.name, depth = row.depth,
        value = cells.value, total = cells.total, odd = odd,
      }
      odd = not odd
    else
      rows[#rows + 1] = row
      odd = true
    end
  end
  return rows
end
