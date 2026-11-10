-- Thin adapter: the Statistics window and its button on the default Statistics tab. It draws what the pure modules
-- (CategoryTree, ListState, Rows, Breakdown, Characters, WindowPosition) compute and reads the game through GameAPI.
local _, ns = ...
local L, GameAPI, Sync = ns.L, ns.GameAPI, ns.Sync
local CategoryTree, ListState, Rows = ns.CategoryTree, ns.ListState, ns.Rows
local Breakdown, Characters, WindowPosition = ns.Breakdown, ns.Characters, ns.WindowPosition

local Window = {}
ns.Window = Window

local FRAME_NAME = "ForeverAccountStatsFrame"
local WIDTH, HEIGHT = 620, 540
-- Sizes of the profession window's recipe list.
local CATEGORY_HEIGHT = 25
local STATISTIC_HEIGHT = 20
local ROW_SPACING = 1
local LIST_PADDING = 5
local INDENT = 10
-- Statistic names start where recipe names do, clear of their Category's header text.
local STATISTIC_INSET = 20
local COLUMN_WIDTH = 120
local COLUMN_GAP = 10
-- Wide enough for the longest Full Name and Ruleset with the class icon.
local DROPDOWN_WIDTH = 320
local DROPDOWN_LEFT = 16
-- The search box fills the rest of the dropdown's line: after the dropdown and a gap, up to 20 short of the right
-- edge.
local SEARCH_GAP = 14
local SEARCH_WIDTH = WIDTH - DROPDOWN_LEFT - DROPDOWN_WIDTH - SEARCH_GAP - 20
local ICON_SIZE = 16
-- Room at the right end of every dropdown entry for the X that Forgets its Character, so the Last Synced times line
-- up whether an entry has one or not.
local FORGET_BUTTON_SPACE = 16 + 4
local FORGET_DIALOG = "FOREVER_ACCOUNT_STATS_FORGET"
-- The default Statistics panel re-reads on every CRITERIA_UPDATE; that event comes in bursts, so wait a little.
local REREAD_DELAY = 0.5

local frame          -- created on first open, once SavedVariables are loaded
local tree           -- the Category tree, read on first open
local list           -- the ListState: Categories expanded and the search since the window opened
local selectedGUID   -- Character chosen in the dropdown since the window opened
local liveValues     -- the logged-in Character's values, read while the window is shown; not saved
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
  liveValues = Sync.buildSnapshot(GameAPI.readStatistics())
end

-- What Rows and Breakdown read: every Tracked Character's values, the logged-in one's read live, and the Character
-- chosen in the dropdown.
local function valuesView()
  return {
    db = ForeverAccountStatsDB,
    selectedGUID = selectedGUID,
    currentGUID = GameAPI.playerGUID(),
    liveValues = liveValues,
  }
end

local function redraw(keepScroll)
  local entry = Characters.selectedEntry(dropdownEntries(), selectedGUID)
  selectedGUID = entry and entry.guid
  local rows = Rows.build(ListState.visibleRows(list), valuesView())
  frame.ScrollBox:SetDataProvider(CreateDataProvider(rows), keepScroll and ScrollBoxConstants.RetainScrollPosition)
end

-- Fills GameTooltip with the Breakdown of the Statistic `data` under its full name: each Character class-coloured
-- with its value on the right. False when the Statistic has no Account Total, so no Breakdown.
local function showBreakdown(data)
  local breakdown = Breakdown.build(data.id, valuesView())
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
-- the window falls back to the logged-in Character (see Characters.selectedEntry).
local function forget(guid)
  ForeverAccountStatsDB = Sync.forget(ForeverAccountStatsDB, guid, GameAPI.playerGUID())
  if frame:IsShown() then
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
    if frame:IsShown() then
      readLiveValues()
      redraw(true)
    end
  end)
end

-- Rows look like the profession window's recipe list: Categories on its header bar with the +/- on the right,
-- Statistics as plain white lines with a soft hover glow.
local function createRegions(row)
  row.HeaderLeft = row:CreateTexture(nil, "BACKGROUND")
  row.HeaderLeft:SetAtlas("Professions-recipe-header-left", true)
  row.HeaderLeft:SetPoint("LEFT", 0, 2)
  row.HeaderRight = row:CreateTexture(nil, "BACKGROUND")
  row.HeaderRight:SetAtlas("Professions-recipe-header-right", true)
  row.HeaderRight:SetPoint("RIGHT", 0, 2)
  row.HeaderMiddle = row:CreateTexture(nil, "BACKGROUND")
  row.HeaderMiddle:SetAtlas("Professions-recipe-header-middle", false)
  row.HeaderMiddle:SetPoint("TOPLEFT", row.HeaderLeft, "TOPRIGHT")
  row.HeaderMiddle:SetPoint("BOTTOMRIGHT", row.HeaderRight, "BOTTOMLEFT")

  row.CollapseIcon = row:CreateTexture(nil, "ARTWORK")
  row.CollapseIcon:SetPoint("RIGHT", -10, 2)
  row.CollapseIconGlow = row:CreateTexture(nil, "HIGHLIGHT")
  row.CollapseIconGlow:SetBlendMode("ADD")
  row.CollapseIconGlow:SetPoint("CENTER", row.CollapseIcon)
  row.Title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal_NoShadow")
  row.Title:SetPoint("LEFT", 10, 2)
  row.Title:SetPoint("RIGHT", row.CollapseIcon, "LEFT", -5, 0)
  row.Title:SetJustifyH("LEFT")
  row.Title:SetWordWrap(false)

  row.HoverGlow = row:CreateTexture(nil, "HIGHLIGHT")
  row.HoverGlow:SetAtlas("Professions_Recipe_Hover", false)
  row.HoverGlow:SetAllPoints()
  row.HoverGlow:SetAlpha(0.5)
  row.Total = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight_NoShadow")
  row.Total:SetPoint("RIGHT", -10, 0)
  row.Total:SetWidth(COLUMN_WIDTH)
  row.Total:SetJustifyH("RIGHT")
  row.Value = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight_NoShadow")
  row.Value:SetPoint("RIGHT", row.Total, "LEFT", -COLUMN_GAP, 0)
  row.Value:SetWidth(COLUMN_WIDTH)
  row.Value:SetJustifyH("RIGHT")
  row.Name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight_NoShadow")
  row.Name:SetPoint("LEFT", STATISTIC_INSET, 0)
  row.Name:SetPoint("RIGHT", row.Value, "LEFT", -COLUMN_GAP, 0)
  row.Name:SetJustifyH("LEFT")
  row.Name:SetWordWrap(false)

  row:SetScript("OnClick", function(self)
    if self.data.kind == "category" then
      list = ListState.toggled(list, self.data.id)
      redraw(true)
    end
  end)
  -- A Statistic row shows its Account Total's Breakdown, or else its full name when cut short.
  row:SetScript("OnEnter", function(self)
    if self.data.kind == "category" then
      self.Title:SetFontObject(GameFontHighlight_NoShadow)
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
    self.Title:SetFontObject(GameFontNormal_NoShadow)
    GameTooltip_Hide()
  end)
end

-- Pooled rows serve both kinds, so every region is set every time.
local function initRow(row, data)
  if not row.Title then
    createRegions(row)
  end
  row.data = data
  local isCategory = data.kind == "category"
  row.HeaderLeft:SetShown(isCategory)
  row.HeaderMiddle:SetShown(isCategory)
  row.HeaderRight:SetShown(isCategory)
  row.CollapseIcon:SetShown(isCategory)
  row.CollapseIconGlow:SetShown(isCategory)
  row.Title:SetShown(isCategory)
  row.HoverGlow:SetShown(not isCategory)
  row.Name:SetShown(not isCategory)
  row.Value:SetShown(not isCategory)
  row.Total:SetShown(not isCategory)
  if isCategory then
    local atlas = data.expanded and "Professions-recipe-header-collapse" or "Professions-recipe-header-expand"
    row.CollapseIcon:SetAtlas(atlas, true)
    row.CollapseIconGlow:SetAtlas(atlas, true)
    row.Title:SetFontObject(GameFontNormal_NoShadow)
    row.Title:SetText(data.name)
  else
    row.Name:SetText(data.name)
    row.Value:SetText(data.value)
    row.Total:SetText(data.total)
  end
end

local function createList(parent)
  local scrollBox = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
  scrollBox:SetPoint("TOPLEFT", 4, -22)
  scrollBox:SetPoint("BOTTOMRIGHT", -22, 4)
  local scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
  scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 6, -2)
  scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 6, 2)

  -- The profession list's dark background behind the rows.
  local background = parent:CreateTexture(nil, "BACKGROUND", nil, 1)
  background:SetAtlas("Professions-background-summarylist")
  background:SetAllPoints()

  local view = CreateScrollBoxListLinearView(LIST_PADDING, LIST_PADDING, LIST_PADDING, 0, ROW_SPACING)
  view:SetElementExtentCalculator(function(_, data)
    return data.kind == "category" and CATEGORY_HEIGHT or STATISTIC_HEIGHT
  end)
  view:SetElementInitializer("Button", initRow)
  view:SetElementIndentCalculator(function(data)
    return data.depth * INDENT
  end)
  ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

  -- Column headings, lined up with the rows' cells.
  local totalHeading = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  totalHeading:SetPoint("BOTTOMRIGHT", scrollBox, "TOPRIGHT", -5, 4)
  totalHeading:SetWidth(COLUMN_WIDTH)
  totalHeading:SetJustifyH("RIGHT")
  totalHeading:SetText(L.ACCOUNT_TOTAL_COLUMN)
  local characterHeading = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  characterHeading:SetPoint("RIGHT", totalHeading, "LEFT", -COLUMN_GAP, 0)
  characterHeading:SetWidth(COLUMN_WIDTH)
  characterHeading:SetJustifyH("RIGHT")
  characterHeading:SetText(L.CHARACTER_COLUMN)
  local statisticHeading = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  statisticHeading:SetPoint("BOTTOMLEFT", scrollBox, "TOPLEFT", 5, 4)
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
        return data.guid == selectedGUID
      end, function(data)
        selectedGUID = data.guid
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
-- expanded before (see ListState).
local function createSearchBox(parent, dropdown)
  local searchBox = CreateFrame("EditBox", nil, parent, "SearchBoxTemplate")
  searchBox:SetSize(SEARCH_WIDTH, 20)
  searchBox:SetPoint("LEFT", dropdown, "RIGHT", SEARCH_GAP, 0)
  searchBox:SetAutoFocus(false)
  searchBox.Instructions:SetText(L.SEARCH_PLACEHOLDER)
  searchBox:HookScript("OnTextChanged", function(self)
    list = ListState.searched(list, self:GetText())
    -- The window's OnHide empties the box as well, which lands here with the window already hidden: then leave
    -- the list undrawn, as OnShow redraws it on the next open.
    if parent:IsShown() then
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
  tree = CategoryTree.build(categories.categories, categories.statistics)
  list = ListState.new(tree)

  frame = CreateFrame("Frame", FRAME_NAME, UIParent, "ButtonFrameTemplate")
  frame:SetSize(WIDTH, HEIGHT)
  frame:SetTitle(L.ADDON_TITLE)
  ButtonFrameTemplate_HidePortrait(frame)
  ButtonFrameTemplate_HideButtonBar(frame)
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
    readLiveValues()
    redraw(false)
    self.Dropdown:GenerateMenu()
  end)
  -- Closing forgets the expanded Categories, the chosen Character and the search: the next open starts collapsed,
  -- on the logged-in Character, with an empty search box.
  frame:SetScript("OnHide", function(self)
    self:UnregisterEvent("CRITERIA_UPDATE")
    selectedGUID = nil
    -- Fires the search box's OnTextChanged, which skips its redraw while the window is hidden.
    self.SearchBox:SetText("")
    list = ListState.new(tree)
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
