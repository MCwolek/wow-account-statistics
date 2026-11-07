-- Thin adapter: the Statistics window and its button on the default Statistics tab. It draws what the pure modules
-- (CategoryTree, Cells, Characters, WindowPosition) compute and reads the game through GameAPI.
local _, ns = ...
local L, GameAPI, Sync = ns.L, ns.GameAPI, ns.Sync
local CategoryTree, Cells, Characters, WindowPosition = ns.CategoryTree, ns.Cells, ns.Characters, ns.WindowPosition

local Window = {}
ns.Window = Window

local FRAME_NAME = "ForeverAccountStatsFrame"
local WIDTH, HEIGHT = 620, 540
local ROW_HEIGHT = 24
local INDENT = 12
local COLUMN_WIDTH = 120
local COLUMN_GAP = 10
local DROPDOWN_WIDTH = 260
-- The default Statistics panel re-reads on every CRITERIA_UPDATE; that event comes in bursts, so wait a little.
local LIVE_REFRESH_DELAY = 0.5
local STAT_TEXTURE = "Interface\\AchievementFrame\\UI-Achievement-Stat-Buttons"
local EXPAND_TEXTURE = "Interface\\Buttons\\UI-PlusButton-Up"
local COLLAPSE_TEXTURE = "Interface\\Buttons\\UI-MinusButton-Up"
local VALUE_R, VALUE_G, VALUE_B = 1, 0.97, 0.6

local frame          -- created on first open, once SavedVariables are loaded
local tree           -- the Category tree, read on first open
local expanded = {}  -- Categories expanded since the window opened
local selectedGUID   -- Character chosen in the dropdown since the window opened
local liveSnapshot   -- the logged-in Character's values, read while the window is shown
local refreshPending = false

local function db()
  return ForeverAccountStatsDB
end

local function dropdownEntries()
  return Characters.dropdownEntries(db(), GameAPI.playerGUID(), GameAPI.now())
end

-- Full Name and Ruleset with the class icon and in the class colour; a class the game does not colour stays white.
local function characterLabel(entry)
  if not entry.class then
    return entry.label
  end
  local label = entry.label
  local color = C_ClassColor.GetClassColor(entry.class)
  if color then
    label = color:WrapTextInColorCode(label)
  end
  return CreateAtlasMarkup(GetClassAtlas(entry.class), 14, 14) .. " " .. label
end

local function readLive()
  liveSnapshot = Sync.buildSnapshot(GameAPI.readStatistics())
end

local function refresh(keepScroll)
  local currentGUID = GameAPI.playerGUID()
  local entry = Characters.selectedEntry(dropdownEntries(), selectedGUID)
  selectedGUID = entry and entry.guid or currentGUID
  if entry then
    frame.lastSynced = Characters.lastSynced(entry, GameAPI.now(), GameAPI.formatDate)
    frame.LastSyncedText:SetText(frame.lastSynced.text)
  end
  local visible = CategoryTree.visibleRows(tree, expanded)
  local rows = Cells.rows(visible, db(), selectedGUID, currentGUID, liveSnapshot)
  frame.ScrollBox:SetDataProvider(CreateDataProvider(rows), keepScroll and ScrollBoxConstants.RetainScrollPosition)
end

local function scheduleLiveRefresh()
  if refreshPending then
    return
  end
  refreshPending = true
  C_Timer.After(LIVE_REFRESH_DELAY, function()
    refreshPending = false
    if frame:IsShown() then
      readLive()
      refresh(true)
    end
  end)
end

local function createRegions(row)
  row.Background = row:CreateTexture(nil, "BACKGROUND")
  row.Background:SetAllPoints()
  row.Background:SetTexture(STAT_TEXTURE)

  row.HeaderLeft = row:CreateTexture(nil, "BACKGROUND")
  row.HeaderLeft:SetTexture(STAT_TEXTURE)
  row.HeaderLeft:SetSize(23, 23)
  row.HeaderLeft:SetPoint("BOTTOMLEFT", 0, -1)
  row.HeaderLeft:SetTexCoord(0, 0.08984375, 0, 0.1796875)
  row.HeaderRight = row:CreateTexture(nil, "BACKGROUND")
  row.HeaderRight:SetTexture(STAT_TEXTURE)
  row.HeaderRight:SetSize(23, 23)
  row.HeaderRight:SetPoint("BOTTOMRIGHT", 0, -1)
  row.HeaderRight:SetTexCoord(0.91015625, 1, 0, 0.1796875)
  row.HeaderMiddle = row:CreateTexture(nil, "BACKGROUND")
  row.HeaderMiddle:SetTexture(STAT_TEXTURE)
  row.HeaderMiddle:SetHeight(23)
  row.HeaderMiddle:SetPoint("TOPLEFT", row.HeaderLeft, "TOPRIGHT")
  row.HeaderMiddle:SetPoint("TOPRIGHT", row.HeaderRight, "TOPLEFT")
  row.HeaderMiddle:SetTexCoord(0.08984375, 0.91015625, 0, 0.1796875)

  row.ExpandIcon = row:CreateTexture(nil, "ARTWORK")
  row.ExpandIcon:SetSize(16, 16)
  row.ExpandIcon:SetPoint("LEFT", 6, 0)
  row.Title = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  row.Title:SetPoint("LEFT", row.ExpandIcon, "RIGHT", 6, 0)
  row.Title:SetPoint("RIGHT", -8, 0)
  row.Title:SetJustifyH("LEFT")
  row.Title:SetWordWrap(false)

  row.Total = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightRight")
  row.Total:SetPoint("RIGHT", -5, 0)
  row.Total:SetWidth(COLUMN_WIDTH)
  row.Total:SetTextColor(VALUE_R, VALUE_G, VALUE_B)
  row.Value = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightRight")
  row.Value:SetPoint("RIGHT", row.Total, "LEFT", -COLUMN_GAP, 0)
  row.Value:SetWidth(COLUMN_WIDTH)
  row.Value:SetTextColor(VALUE_R, VALUE_G, VALUE_B)
  row.Name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightLeft")
  row.Name:SetPoint("LEFT", 5, 0)
  row.Name:SetPoint("RIGHT", row.Value, "LEFT", -COLUMN_GAP, 0)
  row.Name:SetWordWrap(false)

  row:SetScript("OnClick", function(self)
    if self.data.kind == "category" then
      expanded[self.data.id] = not expanded[self.data.id] or nil
      refresh(true)
    end
  end)
  row:SetScript("OnEnter", function(self)
    if self.data.kind == "statistic" and self.Name:IsTruncated() then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(self.data.name, 1, 1, 1, 1, true)
      GameTooltip:Show()
    end
  end)
  row:SetScript("OnLeave", GameTooltip_Hide)
end

-- Pooled rows serve both kinds, so every region is set every time.
local function initRow(row, data)
  if not row.Background then
    createRegions(row)
  end
  row.data = data
  local isCategory = data.kind == "category"
  row.HeaderLeft:SetShown(isCategory)
  row.HeaderMiddle:SetShown(isCategory)
  row.HeaderRight:SetShown(isCategory)
  row.ExpandIcon:SetShown(isCategory)
  row.Title:SetShown(isCategory)
  row.Background:SetShown(not isCategory)
  row.Name:SetShown(not isCategory)
  row.Value:SetShown(not isCategory)
  row.Total:SetShown(not isCategory)
  if isCategory then
    row.ExpandIcon:SetTexture(data.expanded and COLLAPSE_TEXTURE or EXPAND_TEXTURE)
    row.Title:SetText(data.name)
  else
    -- The default Statistics panel's alternating row backgrounds.
    if data.odd then
      row.Background:SetTexCoord(0, 1, 0.1875, 0.3671875)
      row.Background:SetBlendMode("BLEND")
      row.Background:SetAlpha(1)
    else
      row.Background:SetTexCoord(0, 1, 0.375, 0.5390625)
      row.Background:SetBlendMode("ADD")
      row.Background:SetAlpha(0.5)
    end
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

  local view = CreateScrollBoxListLinearView(2, 2, 0, 0, 0)
  view:SetElementExtent(ROW_HEIGHT)
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
  dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -30)
  dropdown:SetWidth(DROPDOWN_WIDTH)
  -- Re-run whenever the menu opens, so the relative Last Synced times are current.
  dropdown:SetupMenu(function(_, root)
    root:SetScrollMode(20 * 15)
    for _, entry in ipairs(dropdownEntries()) do
      local radio = root:CreateRadio(characterLabel(entry), function(data)
        return data.guid == selectedGUID
      end, function(data)
        selectedGUID = data.guid
        refresh(true)
      end, entry)
      radio:AddInitializer(function(button, description)
        local relative = button:AttachFontString()
        relative:SetPoint("RIGHT")
        relative:SetJustifyH("RIGHT")
        relative:SetFontObject("GameFontDisableSmall")
        relative:SetText(description:GetData().relative)
        button.fontString:SetPoint("RIGHT", relative, "LEFT", -10, 0)
        local width = 20 + button.fontString:GetUnboundedStringWidth() + 10 + relative:GetUnboundedStringWidth()
        return width, 20
      end)
    end
  end)
  return dropdown
end

-- Last Synced of the selected Character beside the dropdown; hovering it shows the exact date and time.
local function createLastSynced(parent, dropdown)
  local text = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  text:SetPoint("LEFT", dropdown, "RIGHT", 12, 0)
  local hover = CreateFrame("Frame", nil, parent)
  hover:SetAllPoints(text)
  hover:SetScript("OnEnter", function(self)
    if not frame.lastSynced then
      return
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(frame.lastSynced.exact, 1, 1, 1)
    GameTooltip:Show()
  end)
  hover:SetScript("OnLeave", GameTooltip_Hide)
  return text
end

local function savePosition(self)
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local point, _, relativePoint, x, y = self:GetPoint(1)
  db().window = WindowPosition.save(point, relativePoint, x, y)
end

local function create()
  local categories = GameAPI.readCategories()
  tree = CategoryTree.build(categories.categories, categories.statistics)

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
  local point, relativePoint, x, y = WindowPosition.anchor(db().window)
  frame:SetPoint(point, UIParent, relativePoint, x, y)

  frame.ScrollBox = createList(frame.Inset)
  frame.Dropdown = createDropdown(frame)
  frame.LastSyncedText = createLastSynced(frame, frame.Dropdown)

  frame:SetScript("OnShow", function(self)
    self:RegisterEvent("CRITERIA_UPDATE")
    readLive()
    refresh(false)
    self.Dropdown:GenerateMenu()
  end)
  -- Closing forgets the expanded Categories and the chosen Character: the next open starts collapsed, on the
  -- logged-in Character.
  frame:SetScript("OnHide", function(self)
    self:UnregisterEvent("CRITERIA_UPDATE")
    expanded = {}
    selectedGUID = nil
  end)
  frame:SetScript("OnEvent", scheduleLiveRefresh)
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
  local stats = AchievementFrameStats
  if not stats or Window.statisticsTabButton then
    return
  end
  local button = CreateFrame("Button", nil, stats, "UIPanelButtonTemplate")
  button:SetSize(140, 22)
  button:SetText(L.STATISTICS_TAB_BUTTON)
  -- On the Statistics tab the header's Back button is hidden, which frees its spot.
  local header = AchievementFrame and AchievementFrame.HeaderDetails
  if header then
    button:SetPoint("TOPLEFT", header, "TOPLEFT", 6, -10)
  else
    button:SetPoint("BOTTOMRIGHT", stats, "TOPRIGHT", 0, 4)
  end
  button:SetFrameLevel(stats:GetFrameLevel() + 10)
  button:SetScript("OnClick", Window.toggle)
  Window.statisticsTabButton = button
end
