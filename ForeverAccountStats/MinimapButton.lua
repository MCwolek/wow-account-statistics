-- Thin adapter: the Minimap button, which opens or closes the Statistics window. Where it sits and whether it is shown
-- come from MinimapButtonSettings, saved in ForeverAccountStatsDB.minimapButton.
local _, ns = ...
local L, GameAPI, Window = ns.L, ns.GameAPI, ns.Window
local MinimapButtonSettings, MinimapRing = ns.MinimapButtonSettings, ns.MinimapRing

local MinimapButton = {}
ns.MinimapButton = MinimapButton

local BUTTON_NAME = "ForeverAccountStatsMinimapButton"
-- The default UI's round button on a ring, as on the world map's tracking options button.
local SIZE = 32
local BACKGROUND = "Interface/Minimap/UI-Minimap-Background"
local BORDER = "Interface/Minimap/MiniMap-TrackingBorder"
local HIGHLIGHT = "Interface/Minimap/UI-Minimap-ZoomButton-Highlight"
local ICON_MASK = "Interface/CharacterFrame/TempPortraitAlphaMask"
local ICON_LEFT, ICON_TOP = 7, -6
-- How far outside the Minimap's round edge the button's centre sits, so it straddles the Minimap's ring.
local OUTSIDE_EDGE = 5

local button

local function place(angle)
  local x, y = MinimapRing.offset(angle, Minimap:GetWidth() / 2 + OUTSIDE_EDGE)
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- The angle of the cursor around the Minimap's centre.
local function cursorAngle()
  local cursorX, cursorY = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  local centerX, centerY = Minimap:GetCenter()
  return MinimapRing.angleTowards(cursorX / scale - centerX, cursorY / scale - centerY)
end

local function followCursor()
  place(cursorAngle())
end

-- Holding the left mouse button down, which clicks or drags the button, nudges the icon 1px right and down, as the
-- default UI's Minimap buttons do.
local function setIconPressed(self, pressed)
  local nudge = pressed and 1 or 0
  self.Icon:SetPoint("TOPLEFT", ICON_LEFT + nudge, ICON_TOP - nudge)
end

-- Puts the button at its saved angle, on the ring as wide as the Minimap is now.
local function placeAtSavedAngle()
  place(MinimapButtonSettings.angle(ForeverAccountStatsDB.minimapButton))
end

local function startDrag(self)
  GameTooltip_Hide()
  self:SetScript("OnUpdate", followCursor)
end

local function stopDrag(self)
  self:SetScript("OnUpdate", nil)
  setIconPressed(self, false)
  ForeverAccountStatsDB.minimapButton = MinimapButtonSettings.moved(ForeverAccountStatsDB.minimapButton, cursorAngle())
  placeAtSavedAngle()
end

-- The add-on's name in gold with its version in green on the right, then the left click in grey and what it does in
-- gold, as other add-ons' Minimap buttons show theirs.
local function showTooltip(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  local noWrap = false
  GameTooltip_AddColoredDoubleLine(GameTooltip, L.ADDON_TITLE, GameAPI.addOnVersion(), NORMAL_FONT_COLOR,
    GREEN_FONT_COLOR, noWrap)
  GameTooltip_AddNormalLine(GameTooltip,
    LIGHTGRAY_FONT_COLOR:WrapTextInColorCode(L.MINIMAP_BUTTON_LEFT_CLICK) .. " " .. L.MINIMAP_BUTTON_LEFT_CLICK_ACTION)
  GameTooltip:Show()
end

local function create()
  button = CreateFrame("Button", BUTTON_NAME, Minimap)
  button:SetSize(SIZE, SIZE)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(Minimap:GetFrameLevel() + 8)

  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetTexture(BACKGROUND)
  background:SetSize(25, 25)
  background:SetPoint("TOPLEFT", 2, -4)
  button.Icon = button:CreateTexture(nil, "ARTWORK")
  button.Icon:SetTexture(Window.PORTRAIT_ICON)
  button.Icon:SetSize(20, 20)
  setIconPressed(button, false)
  local mask = button:CreateMaskTexture()
  mask:SetTexture(ICON_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
  mask:SetAllPoints(button.Icon)
  button.Icon:AddMaskTexture(mask)
  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetTexture(BORDER)
  border:SetSize(54, 54)
  border:SetPoint("TOPLEFT")
  button:SetHighlightTexture(HIGHLIGHT, "ADD")

  button:RegisterForClicks("LeftButtonUp")
  button:RegisterForDrag("LeftButton")
  button:SetScript("OnClick", Window.toggle)
  button:SetScript("OnDragStart", startDrag)
  button:SetScript("OnDragStop", stopDrag)
  button:SetScript("OnEnter", showTooltip)
  button:SetScript("OnLeave", GameTooltip_Hide)
  button:SetScript("OnMouseDown", function(self, mouseButton)
    if mouseButton == "LeftButton" then
      setIconPressed(self, true)
    end
  end)
  button:SetScript("OnMouseUp", function(self, mouseButton)
    if mouseButton == "LeftButton" then
      setIconPressed(self, false)
    end
  end)
  button:SetScript("OnHide", function(self)
    setIconPressed(self, false)
  end)
  -- Edit Mode's Minimap size scales the Minimap, which the button follows as its child. Whatever resizes the Minimap
  -- itself, such as another add-on, changes the ring's radius, so the button is placed on the new ring.
  Minimap:HookScript("OnSizeChanged", placeAtSavedAngle)
end

-- Shows the Minimap button where it was left, or hides it, as ForeverAccountStatsDB.minimapButton says. Call it once
-- SavedVariables are loaded.
function MinimapButton.applySettings()
  local settings = ForeverAccountStatsDB.minimapButton
  if not MinimapButtonSettings.isShown(settings) then
    if button then
      button:Hide()
    end
    return
  end
  if not button then
    create()
  end
  placeAtSavedAngle()
  button:Show()
end

-- Hides the Minimap button if it is shown, or shows it if it is hidden, as /stats minimap does, and saves that.
-- Returns whether it is now shown.
function MinimapButton.toggleShown()
  ForeverAccountStatsDB.minimapButton = MinimapButtonSettings.withShownToggled(ForeverAccountStatsDB.minimapButton)
  MinimapButton.applySettings()
  return MinimapButtonSettings.isShown(ForeverAccountStatsDB.minimapButton)
end
