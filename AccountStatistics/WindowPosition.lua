-- Pure saved position of the Statistics window, kept in AccountStatisticsDB.window.
local _, ns = ...

local WindowPosition = {}
ns.WindowPosition = WindowPosition

-- The position to save from the window's anchor (Region:GetPoint without the relative frame, which is UIParent).
function WindowPosition.save(point, relativePoint, x, y)
  return { point = point, relativePoint = relativePoint, x = x, y = y }
end

-- point, relativePoint, x, y to anchor the window to UIParent: the saved position, or the centre of the screen when
-- none is saved or the saved one is incomplete.
function WindowPosition.anchor(saved)
  if type(saved) ~= "table" or type(saved.point) ~= "string" or type(saved.relativePoint) ~= "string"
    or type(saved.x) ~= "number" or type(saved.y) ~= "number" then
    return "CENTER", "CENTER", 0, 0
  end
  return saved.point, saved.relativePoint, saved.x, saved.y
end
