-- Pure choice of where a button's tooltip goes: on the side of the button facing the screen's centre, as LibDBIcon
-- places the tooltips of other add-ons' Minimap buttons.
local _, ns = ...

local TooltipAnchor = {}
ns.TooltipAnchor = TooltipAnchor

-- The tooltip's point and the button's point to pin it to, for a button centred at `x`, `y` on a screen `width` by
-- `height`: below a button in the top half, above one in the bottom half; right edges lined up in the right third,
-- left edges in the left third, centred between them.
function TooltipAnchor.towardScreenCentre(x, y, width, height)
  local side = (x > width * 2 / 3) and "RIGHT" or (x < width / 3) and "LEFT" or ""
  if y > height / 2 then
    return "TOP" .. side, "BOTTOM" .. side
  end
  return "BOTTOM" .. side, "TOP" .. side
end
