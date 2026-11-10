-- Pure geometry of the circle around the Minimap's centre that the Minimap button moves along. Angles are in degrees,
-- counterclockwise from the Minimap's right edge, as math.atan2 measures them.
local _, ns = ...

local MinimapRing = {}
ns.MinimapRing = MinimapRing

-- The angle of the point `x`, `y` away from the Minimap's centre, such as the cursor while the button is dragged.
function MinimapRing.angleTowards(x, y)
  return math.deg(math.atan2(y, x)) % 360
end

-- x, y from the Minimap's centre to the button's centre at `angle`, `radius` away.
function MinimapRing.offset(angle, radius)
  local radians = math.rad(angle)
  return math.cos(radians) * radius, math.sin(radians) * radius
end
