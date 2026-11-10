-- Pure saved settings of the Minimap button, kept in ForeverAccountStatsDB.minimapButton: whether it is shown and
-- where on the Minimap's edge it sits.
local _, ns = ...

local MinimapButtonSettings = {}
ns.MinimapButtonSettings = MinimapButtonSettings

-- A copy of the saved settings, or empty ones when none are saved yet.
local function copy(saved)
  if type(saved) ~= "table" then
    return {}
  end
  return { hidden = saved.hidden, angle = saved.angle }
end

-- Whether the Minimap button is shown: it is until hidden with /stats minimap.
function MinimapButtonSettings.isShown(saved)
  return not (type(saved) == "table" and saved.hidden == true)
end

-- The settings to save once /stats minimap hides a shown button or shows a hidden one.
function MinimapButtonSettings.withShownToggled(saved)
  local settings = copy(saved)
  settings.hidden = MinimapButtonSettings.isShown(saved) or nil
  return settings
end

-- Angles are in degrees around the Minimap's centre, as MinimapRing measures them.
-- The lower left of the Minimap, clear of the default UI's own buttons.
local DEFAULT_ANGLE = 225

-- The saved angle of the Minimap button, or the default one when none is saved.
function MinimapButtonSettings.angle(saved)
  if type(saved) == "table" and type(saved.angle) == "number" then
    return saved.angle
  end
  return DEFAULT_ANGLE
end

-- The settings to save once the Minimap button is dragged to `angle`; any angle is kept within one turn.
function MinimapButtonSettings.moved(saved, angle)
  local settings = copy(saved)
  settings.angle = angle % 360
  return settings
end
