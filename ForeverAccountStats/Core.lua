-- Wiring: game events and the /stats command (list, dump <Statistic ID>). Logic lives in Sync.lua and Listing.lua.
local addonName, ns = ...
local Sync, Listing, GameAPI = ns.Sync, ns.Listing, ns.GameAPI

local function sync()
  local character = Sync.character(GameAPI.readPlayer())
  local snapshot = Sync.buildSnapshot(GameAPI.readStatistics())
  ForeverAccountStatsDB = Sync.record(ForeverAccountStatsDB, character, snapshot, GameAPI.now())
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == addonName then
    ForeverAccountStatsDB = Sync.ensureDB(ForeverAccountStatsDB)
  elseif event == "PLAYER_LOGIN" or event == "PLAYER_LOGOUT" then
    sync()
  end
end)

-- ForeverAccountStatsDB exists by now: ADDON_LOADED fires before the player can type a command.
SLASH_FOREVERACCOUNTSTATS1 = "/stats"
SlashCmdList.FOREVERACCOUNTSTATS = function(message)
  local command = Listing.parseCommand(message or "")
  local lines
  if command.action == "list" then
    lines = Listing.lines(ForeverAccountStatsDB, GameAPI.playerGUID(), GameAPI.now())
  elseif command.action == "dump" then
    local name = GameAPI.statisticName(command.statisticID)
    lines = Listing.statisticLines(ForeverAccountStatsDB, command.statisticID, name)
  else
    lines = { string.format(ns.L.USAGE, ns.L.ADDON_TITLE) }
  end
  for _, line in ipairs(lines) do
    print(line)
  end
end
