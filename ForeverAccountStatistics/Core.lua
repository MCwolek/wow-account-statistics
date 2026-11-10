-- Wiring: game events and the /stats command (see Command.lua). Logic lives in Sync.lua, Command.lua and Listing.lua;
-- the Statistics window in Window.lua and the Minimap button in MinimapButton.lua.
local addonName, ns = ...
local Sync, Command, Listing, GameAPI, Window = ns.Sync, ns.Command, ns.Listing, ns.GameAPI, ns.Window
local MinimapButton = ns.MinimapButton

-- The default UI's Statistics tab lives in this load-on-demand add-on.
local ACHIEVEMENT_UI = "Blizzard_AchievementUI"

local function sync()
  local character = Sync.character(GameAPI.readPlayer())
  local snapshot = Sync.buildSnapshot(GameAPI.readStatistics())
  ForeverAccountStatisticsDB = Sync.record(ForeverAccountStatisticsDB, character, snapshot, GameAPI.now())
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == addonName then
    ForeverAccountStatisticsDB = Sync.ensureDB(ForeverAccountStatisticsDB)
    MinimapButton.applySettings()
    -- Another add-on may have loaded the Achievement UI before this one.
    if GameAPI.isAddOnLoaded(ACHIEVEMENT_UI) then
      Window.addStatisticsTabButton()
    end
  elseif event == "ADDON_LOADED" and arg1 == ACHIEVEMENT_UI then
    Window.addStatisticsTabButton()
  elseif event == "PLAYER_LOGIN" or event == "PLAYER_LOGOUT" then
    sync()
  end
end)

-- ForeverAccountStatisticsDB exists by now: ADDON_LOADED fires before the player can type a command.
SLASH_FOREVERACCOUNTSTATS1 = "/stats"
SlashCmdList.FOREVERACCOUNTSTATS = function(message)
  local command = Command.parse(message or "")
  if command.action == "toggle" then
    Window.toggle()
    return
  end
  local lines
  if command.action == "minimap" then
    local confirmation = MinimapButton.toggleShown() and ns.L.MINIMAP_BUTTON_SHOWN or ns.L.MINIMAP_BUTTON_HIDDEN
    lines = { string.format(confirmation, ns.L.ADDON_TITLE) }
  elseif command.action == "list" then
    lines = Listing.lines(ForeverAccountStatisticsDB, GameAPI.playerGUID(), GameAPI.now())
  elseif command.action == "dump" then
    local name = GameAPI.statisticName(command.statisticID)
    lines = Listing.statisticLines(
      ForeverAccountStatisticsDB, GameAPI.playerGUID(), GameAPI.now(), command.statisticID, name)
  else
    lines = { string.format(ns.L.USAGE, ns.L.ADDON_TITLE) }
  end
  for _, line in ipairs(lines) do
    print(line)
  end
end
