-- Thin adapter: the Statistics window and its button on the default Statistics tab. It forwards the window's actions
-- to its Window Session (see WindowSession), draws what the pure modules (WindowSession, CategoryTree, RowLayout,
-- Characters, WindowPosition) compute and reads the game through GameAPI.
local _, ns = ...
local L, GameAPI, Sync = ns.L, ns.GameAPI, ns.Sync
local CategoryTree, RowLayout, WindowSession = ns.CategoryTree, ns.RowLayout, ns.WindowSession
local Characters, WindowPosition = ns.Characters, ns.WindowPosition

local Window = {}
ns.Window = Window

local FRAME_NAME = "ForeverAccountStatsFrame"
local WIDTH, HEIGHT = 620, 540
-- The Statistics side tab's icon in the Character frame, shown in the window's portrait circle.
local PORTRAIT_ICON = "Interface/ICONS/INV_SideTab_Stats_c60"
-- The Character frame's backdrop behind its Statistics tab, from just under the title bar down.
local BODY_BACKGROUND = "UI-Character-Info-General-BG"
local BODY_TOP = -20
local COLUMN_WIDTH = 120
local COLUMN_GAP = 10
-- Wide enough for the longest Full Name and Ruleset with the class icon.
local DROPDOWN_WIDTH = 320
-- Right of the portrait circle, which reaches 57 in from the window's left edge.
local DROPDOWN_LEFT = 62
-- The search box fills the rest of the dropdown's line: after the dropdown and a gap, up to 20 short of the right
-- edge.
local SEARCH_GAP = 14
local SEARCH_WIDTH = WIDTH - DROPDOWN_LEFT - DROPDOWN_WIDTH - SEARCH_GAP - 20
local ICON_SIZE = 16
-- Room at the right end of every dropdown entry for the X that Forgets its Character, so the Last Synced times line
-- up whether an entry has one or not.
local FORGET_BUTTON_SIZE = 16   -- the size MenuTemplates gives its utility buttons
local FORGET_BUTTON_GAP = 4
local FORGET_BUTTON_SPACE = FORGET_BUTTON_SIZE + FORGET_BUTTON_GAP
local FORGET_DIALOG = "FOREVER_ACCOUNT_STATS_FORGET"
-- The default Statistics panel re-reads on every CRITERIA_UPDATE; that event comes in bursts, so wait a little.
local REREAD_DELAY = 0.5

local frame          -- created on first open, once SavedVariables are loaded
local session        -- the Window Session, created with the frame
local rereadPending = false
local statisticsTabButton

local function dropdownEntries()
  return Characters.dropdownEntries(ForeverAccountStatsDB, GameAPI.playerGUID(), GameAPI.now())
end

-- Full Name and Ruleset in the class colour; a class the game does not colour stays white.
local function coloredLabel(entry)
  local color = entry.class and C_ClassColor.GetClassColor(entry.class)
  if color then
    return color:WrapTextInColorCode(entry.label)
  end
  return entry.label
end

-- The coloured label with the class icon in front, for the closed dropdown.
local function selectionLabel(entry)
  if not entry.class then
    return entry.label
  end
  return CreateAtlasMarkup(GetClassAtlas(entry.class), ICON_SIZE, ICON_SIZE) .. " " .. coloredLabel(entry)
end

local function readLiveValues()
  return Sync.buildSnapshot(GameAPI.readStatistics())
end

local function chosenCharacter()
  return WindowSession.chosenCharacter(session, ForeverAccountStatsDB, GameAPI.playerGUID())
end

local function redraw(keepScroll)
  local rows = WindowSession.rows(session, ForeverAccountStatsDB, GameAPI.playerGUID())
  frame.ScrollBox:SetDataProvider(CreateDataProvider(rows), keepScroll and ScrollBoxConstants.RetainScrollPosition)
end

-- Fills GameTooltip with the Breakdown of the Statistic `data` under its full name: each Character class-coloured
-- with its value on the right. False when the Statistic has no Account Total, so no Breakdown.
local function showBreakdown(data)
  local breakdown = WindowSession.breakdown(session, ForeverAccountStatsDB, GameAPI.playerGUID(), data.id)
  if not breakdown then
    return false
  end
  GameTooltip_SetTitle(GameTooltip, data.name)
  for _, line in ipairs(breakdown.lines) do
    GameTooltip:AddDoubleLine(coloredLabel(line), line.value, 1, 1, 1, 1, 1, 1)
  end
  if breakdown.more > 0 then
    GameTooltip:AddLine(L.BREAKDOWN_MORE:format(breakdown.more), GRAY_FONT_COLOR:GetRGB())
  end
  return true
end

-- Forgets the Character `guid` once its confirmation dialog is accepted. When it was the one chosen in the dropdown,
-- the window falls back to the logged-in Character (see WindowSession.chosenCharacter).
local function forget(guid)
  ForeverAccountStatsDB = Sync.forget(ForeverAccountStatsDB, guid, GameAPI.playerGUID())
  if WindowSession.isOpen(session) then
    redraw(true)
    frame.Dropdown:GenerateMenu()
  end
end

local function defineForgetDialog()
  StaticPopupDialogs[FORGET_DIALOG] = {
    text = L.FORGET_CONFIRM,
    button1 = L.FORGET_ACCEPT,
    button2 = L.FORGET_CANCEL,
    -- `data` is the GUID given to StaticPopup_Show. Returns nothing, so the dialog closes.
    OnAccept = function(_, data)
      forget(data)
    end,
    showAlert = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
  }
end

local function scheduleReread()
  if rereadPending then
    return
  end
  rereadPending = true
  C_Timer.After(REREAD_DELAY, function()
    rereadPending = false
    if WindowSession.isOpen(session) then
      session = WindowSession.liveValuesRead(session, readLiveValues())
      redraw(true)
    end
  end)
end

-- Rows look like the game's Statistics tab in the Character frame, in three looks (see RowLayout): a top-level
-- Category on its bar in gold, with the +/- on the right; a nested Category in white, with the open/closed icon on the
-- left; a Statistic as a plain white line. A nested Category and a Statistic draw their name, values and a faint white
-- hover line on a content frame of their own; a top-level Category brightens its bar when hovered instead. Holding the
-- mouse button down on a row nudges it 1px right and down: a top-level Category's name, or the whole content frame of
-- the others. A nested Category's name stays beside its open/closed icon, which does not move.
local CATEGORY_BAR = "common-button-list-collapseExpand"
local CATEGORY_BAR_HOVER_ALPHA = 0.3
local HOVER_LINE_SIDE = "charactercreate-customize-dropdown-linemouseover-side"
local HOVER_LINE_MIDDLE = "charactercreate-customize-dropdown-linemouseover-middle"
local HOVER_LINE_SIDE_WIDTH = 6
local HOVER_LINE_ALPHA = 0.10
local NESTED_TOGGLE_SIZE = 20
local NESTED_TOGGLE_HIGHLIGHT = "Interface/Buttons/UI-PlusButton-Hilight"
-- A top-level Category's +/-, in from the bar's right end and a little below its middle.
local STATE_ICON_RIGHT = -8
local STATE_ICON_Y = -1
-- Where the text sits in each look: a top-level Category's name, stopping short of its +/-; a Statistic's name and a
-- nested Category's open/closed icon at the same spot, with the nested Category's name just right of the icon.
local CATEGORY_TEXT_LEFT = 10
local CATEGORY_TEXT_GAP = 5
local ENTRY_LEFT = 2
local NESTED_TEXT_GAP = 4
local NESTED_TEXT_RIGHT = -24
local TOTAL_RIGHT = -12
-- How far a row moves while the mouse button is held down on it.
local PRESSED_X, PRESSED_Y = 1, -1

local function toggleCategory(categoryID)
  session = WindowSession.categoryToggled(session, categoryID)
  redraw(true)
end

-- One rounded end of the hover line, on the `side` ("LEFT" or "RIGHT") of `content`; the right one is the left one
-- mirrored.
local function createHoverLineEnd(content, side)
  local texture = content:CreateTexture(nil, "BACKGROUND")
  texture:SetAtlas(HOVER_LINE_SIDE)
  if side == "RIGHT" then
    local info = C_Texture.GetAtlasInfo(HOVER_LINE_SIDE)
    if info then
      texture:SetTexCoord(info.rightTexCoord, info.leftTexCoord, info.topTexCoord, info.bottomTexCoord)
    end
  end
  texture:SetWidth(HOVER_LINE_SIDE_WIDTH)
  texture:SetPoint("TOP" .. side)
  texture:SetPoint("BOTTOM" .. side)
  return texture
end

-- The faint white line behind a hovered nested Category or Statistic: two rounded ends and a middle.
local function createHoverLine(content)
  local left = createHoverLineEnd(content, "LEFT")
  local right = createHoverLineEnd(content, "RIGHT")
  local middle = content:CreateTexture(nil, "BACKGROUND")
  middle:SetAtlas(HOVER_LINE_MIDDLE)
  middle:SetPoint("TOPLEFT", left, "TOPRIGHT")
  middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
  return { left, middle, right }
end

-- Shown while the mouse is anywhere over the row, its open/closed icon included. A top-level Category hides the
-- content frame the line is on.
local function refreshHoverLine(row)
  local alpha = row:IsMouseOver() and HOVER_LINE_ALPHA or 0
  for _, texture in ipairs(row.HoverLine) do
    texture:SetAlpha(alpha)
  end
end

-- The row's moving part in its place, PRESSED_X and PRESSED_Y off while the row is pressed.
local function place(row)
  local x, y = 0, 0
  if row.pressed then
    x, y = PRESSED_X, PRESSED_Y
  end
  row.look.place(row, x, y)
end

local function placeContent(row, x, y)
  row.Content:ClearAllPoints()
  row.Content:SetPoint("TOPLEFT", x, y)
  row.Content:SetPoint("BOTTOMRIGHT", x, y)
end

-- What each look shows, how it fills and places what it shows, whether clicking it toggles its Category and whether
-- hovering it shows a tooltip. Pooled rows serve all three looks, so every look sets everything it shows.
local REGIONS = { "Bar", "BarHover", "StateIcon", "Title", "Content", "Toggle", "Value", "Total" }
local LOOKS = {
  category = {
    shows = { Bar = true, BarHover = true, StateIcon = true, Title = true },
    togglesCategory = true,
    fill = function(row, data)
      row.StateIcon:SetAtlas(data.expanded and "common-button-list-minus" or "common-button-list-plus", true)
      row.Title:SetText(data.name)
    end,
    place = function(row, x, y)
      row.Title:ClearAllPoints()
      row.Title:SetPoint("LEFT", CATEGORY_TEXT_LEFT + x, y)
      row.Title:SetPoint("RIGHT", row.StateIcon, "LEFT", -CATEGORY_TEXT_GAP + x, y)
    end,
  },
  nestedCategory = {
    shows = { Content = true, Toggle = true },
    togglesCategory = true,
    fill = function(row, data)
      local toggle = row.Toggle
      toggle.atlas = data.expanded and "campaign_headericon_open" or "campaign_headericon_closed"
      toggle.pressedAtlas = toggle.atlas .. "pressed"
      toggle.Icon:SetAtlas(toggle.atlas, true)
      row.Name:SetText(data.name)
      row.Name:ClearAllPoints()
      row.Name:SetPoint("LEFT", toggle, "RIGHT", NESTED_TEXT_GAP, 0)
      row.Name:SetPoint("RIGHT", NESTED_TEXT_RIGHT, 0)
    end,
    place = placeContent,
  },
  statistic = {
    shows = { Content = true, Value = true, Total = true },
    showsTooltip = true,
    fill = function(row, data)
      row.Name:SetText(data.name)
      row.Name:ClearAllPoints()
      row.Name:SetPoint("LEFT", ENTRY_LEFT, 0)
      row.Name:SetPoint("RIGHT", row.Value, "LEFT", -COLUMN_GAP, 0)
      row.Value:SetText(data.value)
      row.Total:SetText(data.total)
    end,
    place = placeContent,
  },
}

-- The open/closed icon of a nested Category, a button of its own over the content frame that stays put while the row
-- is pressed: it shows the pressed icon while held, and clicking it toggles the Category as clicking the row does.
local function createNestedToggle(row)
  local toggle = CreateFrame("Button", nil, row)
  toggle:SetFrameLevel(row.Content:GetFrameLevel() + 1)
  toggle:SetSize(NESTED_TOGGLE_SIZE, NESTED_TOGGLE_SIZE)
  toggle:SetPoint("LEFT", ENTRY_LEFT, 0)
  toggle:SetHighlightTexture(NESTED_TOGGLE_HIGHLIGHT, "ADD")
  toggle.Icon = toggle:CreateTexture(nil, "ARTWORK")
  toggle.Icon:SetPoint("CENTER")
  toggle:SetScript("OnMouseDown", function(self)
    self.Icon:SetAtlas(self.pressedAtlas, true)
  end)
  toggle:SetScript("OnMouseUp", function(self)
    self.Icon:SetAtlas(self.atlas, true)
  end)
  toggle:SetScript("OnClick", function()
    toggleCategory(row.data.id)
  end)
  toggle:SetScript("OnEnter", function()
    refreshHoverLine(row)
  end)
  toggle:SetScript("OnLeave", function()
    refreshHoverLine(row)
  end)
  return toggle
end

-- The top-level Category's bar, +/- and name, straight on the row.
local function createCategoryRegions(row)
  row.Bar = row:CreateTexture(nil, "BACKGROUND")
  row.Bar:SetAtlas(CATEGORY_BAR)
  row.Bar:SetAllPoints()
  row.BarHover = row:CreateTexture(nil, "HIGHLIGHT")
  row.BarHover:SetAtlas(CATEGORY_BAR)
  row.BarHover:SetAllPoints()
  row.BarHover:SetBlendMode("ADD")
  row.BarHover:SetAlpha(CATEGORY_BAR_HOVER_ALPHA)
  row.StateIcon = row:CreateTexture(nil, "BORDER")
  row.StateIcon:SetPoint("RIGHT", STATE_ICON_RIGHT, STATE_ICON_Y)
  row.Title = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLeft")
  row.Title:SetWordWrap(false)
end

-- The content frame of a nested Category and a Statistic, with the hover line, name and values on it.
local function createContent(row)
  local content = CreateFrame("Frame", nil, row)
  row.Content = content
  row.HoverLine = createHoverLine(content)
  row.Total = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.Total:SetPoint("RIGHT", TOTAL_RIGHT, 0)
  row.Total:SetWidth(COLUMN_WIDTH)
  row.Total:SetJustifyH("RIGHT")
  row.Value = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.Value:SetPoint("RIGHT", row.Total, "LEFT", -COLUMN_GAP, 0)
  row.Value:SetWidth(COLUMN_WIDTH)
  row.Value:SetJustifyH("RIGHT")
  row.Name = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.Name:SetJustifyH("LEFT")
  row.Name:SetWordWrap(false)
end

local function createRegions(row)
  createCategoryRegions(row)
  createContent(row)
  row.Toggle = createNestedToggle(row)

  row:SetScript("OnClick", function(self)
    if self.look.togglesCategory then
      toggleCategory(self.data.id)
    end
  end)
  row:SetScript("OnMouseDown", function(self)
    self.pressed = true
    place(self)
  end)
  row:SetScript("OnMouseUp", function(self)
    self.pressed = false
    place(self)
  end)
  -- A Statistic row shows its Account Total's Breakdown, or else its full name when cut short.
  row:SetScript("OnEnter", function(self)
    refreshHoverLine(self)
    if not self.look.showsTooltip then
      return
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if showBreakdown(self.data) then
      GameTooltip:Show()
    elseif self.Name:IsTruncated() then
      GameTooltip:SetText(self.data.name, 1, 1, 1, 1, true)
      GameTooltip:Show()
    else
      GameTooltip:Hide()
    end
  end)
  row:SetScript("OnLeave", function(self)
    refreshHoverLine(self)
    GameTooltip_Hide()
  end)
end

local function initRow(row, data)
  if not row.Bar then
    createRegions(row)
  end
  row.data = data
  row.look = LOOKS[data.layout.look]
  row.pressed = false
  for _, key in ipairs(REGIONS) do
    row[key]:SetShown(row.look.shows[key] == true)
  end
  row.look.fill(row, data)
  place(row)
  refreshHoverLine(row)
end

-- The game's Statistics tab draws a line across the top and the bottom edge of its list, over the rows.
local function createList(parent)
  local scrollBox = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
  scrollBox:SetPoint("TOPLEFT", 4, -22)
  scrollBox:SetPoint("BOTTOMRIGHT", -22, 4)
  local scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
  scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 6, -2)
  scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 6, 2)

  local padding = RowLayout.PADDING
  local view = CreateScrollBoxListLinearView(padding, padding, padding, padding, RowLayout.SPACING)
  view:SetElementExtentCalculator(function(_, data)
    return data.layout.height
  end)
  view:SetElementInitializer("Button", initRow)
  view:SetElementIndentCalculator(function(data)
    return data.layout.indent
  end)
  ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

  -- Column headings, lined up with the rows' cells.
  local totalHeading = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  totalHeading:SetPoint("BOTTOMRIGHT", scrollBox, "TOPRIGHT", TOTAL_RIGHT - RowLayout.PADDING, 4)
  totalHeading:SetWidth(COLUMN_WIDTH)
  totalHeading:SetJustifyH("RIGHT")
  totalHeading:SetText(L.ACCOUNT_TOTAL_COLUMN)
  local characterHeading = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  characterHeading:SetPoint("RIGHT", totalHeading, "LEFT", -COLUMN_GAP, 0)
  characterHeading:SetWidth(COLUMN_WIDTH)
  characterHeading:SetJustifyH("RIGHT")
  characterHeading:SetText(L.CHARACTER_COLUMN)
  local statisticHeading = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  statisticHeading:SetPoint("BOTTOMLEFT", scrollBox, "TOPLEFT", RowLayout.PADDING, 4)
  statisticHeading:SetText(L.STATISTIC_COLUMN)

  return scrollBox
end

local function createDropdown(parent)
  local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
  dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", DROPDOWN_LEFT, -30)
  dropdown:SetWidth(DROPDOWN_WIDTH)
  dropdown:SetSelectionTranslator(function(selection)
    return selectionLabel(selection.data)
  end)
  -- Re-run whenever the menu opens, so the relative Last Synced times are current.
  dropdown:SetupMenu(function(_, root)
    root:SetScrollMode(20 * 15)
    for _, entry in ipairs(dropdownEntries()) do
      local radio = root:CreateRadio(coloredLabel(entry), function(data)
        return data.guid == chosenCharacter()
      end, function(data)
        session = WindowSession.characterChosen(session, data.guid)
        redraw(true)
      end, entry)
      -- Hovering an entry shows its exact Last Synced; the menu already reads it relative to now.
      radio:SetTooltip(function(tooltip, description)
        local text = Characters.lastSyncedTooltip(description:GetData(), GameAPI.now(), GameAPI.formatDate)
        GameTooltip_SetTitle(tooltip, text)
      end)
      -- The class icon is its own texture between the radio button and the label, and the label keeps the width
      -- the radio sized it to: an icon inside the label's text, or a label stretched to the right-hand text, made
      -- the label wrap onto two lines and cut the name short.
      radio:AddInitializer(function(button, description, menu)
        local data = description:GetData()
        local label = button.fontString
        label:SetWordWrap(false)
        local iconWidth = 0
        if data.class then
          local icon = button:AttachTexture()
          icon:SetAtlas(GetClassAtlas(data.class))
          icon:SetSize(ICON_SIZE, ICON_SIZE)
          icon:SetPoint("LEFT", button.leftTexture1, "RIGHT", 2, 0)
          label:SetPoint("LEFT", icon, "RIGHT", 4, 0)
          iconWidth = 2 + ICON_SIZE + 4
        end
        local relative = button:AttachFontString()
        relative:SetPoint("RIGHT", -FORGET_BUTTON_SPACE, 0)
        relative:SetJustifyH("RIGHT")
        relative:SetFontObject("GameFontDisableSmall")
        relative:SetText(data.relative)
        -- Every Character but the logged-in one can be Forgotten through an X shown while its entry is hovered, as
        -- the Edit Mode layout dropdown deletes a layout. Clicking it does not choose the Character.
        if not data.isCurrent then
          local forgetButton = MenuTemplates.AttachAutoHideCancelButton(button)
          MenuTemplates.SetUtilityButtonTooltipText(forgetButton, L.FORGET_TOOLTIP)
          -- There is no gear button here: its anchor is simply the entry's right edge, where the X goes.
          MenuTemplates.SetUtilityButtonAnchor(forgetButton, MenuVariants.GearButtonAnchor, button)
          MenuTemplates.SetUtilityButtonClickHandler(forgetButton, function()
            menu:Close()
            StaticPopup_Show(FORGET_DIALOG, data.label, nil, data.guid)
          end)
        end
        local radioWidth = button.leftTexture1:GetWidth()
        local width = radioWidth + iconWidth + label:GetUnboundedStringWidth() + 16 + relative:GetUnboundedStringWidth()
          + FORGET_BUTTON_SPACE
        return width, 20
      end)
    end
  end)
  return dropdown
end

-- Typing shows the search results, every Category expanded; emptying the box brings back the whole list as it was
-- expanded before (see WindowSession.searched).
local function createSearchBox(parent, dropdown)
  local searchBox = CreateFrame("EditBox", nil, parent, "SearchBoxTemplate")
  searchBox:SetSize(SEARCH_WIDTH, 20)
  searchBox:SetPoint("LEFT", dropdown, "RIGHT", SEARCH_GAP, 0)
  searchBox:SetAutoFocus(false)
  searchBox.Instructions:SetText(L.SEARCH_PLACEHOLDER)
  searchBox:HookScript("OnTextChanged", function(self)
    session = WindowSession.searched(session, self:GetText())
    -- The window's OnHide empties the box after closing the Window Session, which ignores the search; the hidden
    -- window stays undrawn until the next open.
    if WindowSession.isOpen(session) then
      redraw(false)
    end
  end)
  return searchBox
end

local function savePosition(self)
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local point, _, relativePoint, x, y = self:GetPoint(1)
  ForeverAccountStatsDB.window = WindowPosition.save(point, relativePoint, x, y)
end

local function create()
  local categories = GameAPI.readCategories()
  session = WindowSession.new(CategoryTree.build(categories.categories, categories.statistics))

  frame = CreateFrame("Frame", FRAME_NAME, UIParent, "ButtonFrameTemplate")
  frame:SetSize(WIDTH, HEIGHT)
  frame:SetTitle(L.ADDON_TITLE)
  ButtonFrameTemplate_ShowPortrait(frame)
  frame:SetPortraitToAsset(PORTRAIT_ICON)
  ButtonFrameTemplate_HideButtonBar(frame)
  -- The Character frame's backdrop in place of the template's rock, streaks and marble inset; the inset stays as
  -- the list's anchor.
  frame.TopTileStreaks:Hide()
  frame.Inset.Bg:Hide()
  frame.Inset.NineSlice:Hide()
  local body = frame:CreateTexture(nil, "BACKGROUND")
  body:SetAtlas(BODY_BACKGROUND)
  body:SetPoint("TOPLEFT", 0, BODY_TOP)
  body:SetPoint("BOTTOMRIGHT")
  frame:SetFrameStrata("HIGH")
  frame:SetToplevel(true)
  frame:SetClampedToScreen(true)
  -- Keep the client's layout cache out of it: the position lives in ForeverAccountStatsDB.window.
  frame:SetDontSavePosition(true)
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", savePosition)
  -- The template's close button goes through HideUIPanel, which fails in combat for an add-on frame.
  frame.CloseButton:SetScript("OnClick", function()
    frame:Hide()
  end)
  table.insert(UISpecialFrames, FRAME_NAME)
  frame:ClearAllPoints()
  local point, relativePoint, x, y = WindowPosition.anchor(ForeverAccountStatsDB.window)
  frame:SetPoint(point, UIParent, relativePoint, x, y)

  frame.ScrollBox = createList(frame.Inset)
  frame.Dropdown = createDropdown(frame)
  frame.SearchBox = createSearchBox(frame, frame.Dropdown)
  defineForgetDialog()

  frame:SetScript("OnShow", function(self)
    self:RegisterEvent("CRITERIA_UPDATE")
    session = WindowSession.opened(session, readLiveValues())
    redraw(false)
    self.Dropdown:GenerateMenu()
  end)
  -- Closing forgets the expanded Categories, the chosen Character and the search (see WindowSession.closed); the
  -- search box is emptied to match.
  frame:SetScript("OnHide", function(self)
    self:UnregisterEvent("CRITERIA_UPDATE")
    session = WindowSession.closed(session)
    self.SearchBox:SetText("")
  end)
  frame:SetScript("OnEvent", scheduleReread)
  frame:Hide()
end

-- Opens the Statistics window, or closes it when open.
function Window.toggle()
  if not frame then
    create()
  end
  frame:SetShown(not frame:IsShown())
end

-- Puts a button that opens the window on the default UI's Statistics tab. Call it once Blizzard_AchievementUI has
-- loaded; it is load-on-demand.
function Window.addStatisticsTabButton()
  local statisticsPanel = AchievementFrameStats
  if not statisticsPanel or statisticsTabButton then
    return
  end
  local button = CreateFrame("Button", nil, statisticsPanel, "UIPanelButtonTemplate")
  button:SetSize(140, 22)
  button:SetText(L.STATISTICS_TAB_BUTTON)
  -- On the Statistics tab the header's Back button is hidden, which frees its spot.
  local header = AchievementFrame and AchievementFrame.HeaderDetails
  if header then
    button:SetPoint("TOPLEFT", header, "TOPLEFT", 6, -10)
  else
    button:SetPoint("BOTTOMRIGHT", statisticsPanel, "TOPRIGHT", 0, 4)
  end
  button:SetFrameLevel(statisticsPanel:GetFrameLevel() + 10)
  button:SetScript("OnClick", Window.toggle)
  statisticsTabButton = button
end
