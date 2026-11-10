-- Pure layout of the Statistics window's list, with the sizes the game's Statistics tab has: each row's look,
-- height and indent, and the spacing between rows and the padding around them.
local _, ns = ...

local RowLayout = {
  SPACING = 3,
  PADDING = 10,
}
ns.RowLayout = RowLayout

local HEIGHTS = { category = 26, statistic = 24, nestedCategory = 22 }
local INDENT = 20

-- How the list lays out `row`, one of CategoryTree.visibleRows: { look, height, indent }. The look is "category" for
-- a top-level Category, on its bar with the +/- on the right, "nestedCategory" for one inside another, with the
-- open/closed icon on the left, or "statistic". Each depth indents the row by 20.
function RowLayout.of(row)
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
