-- Wiring: game events and the /fas command. Logic lives in Sync.lua and Listing.lua.
local addonName, ns = ...
local Sync, Listing, GameAPI = ns.Sync, ns.Listing, ns.GameAPI

local function sync()
  local character = GameAPI.readCharacter()
  local snapshot = Sync.buildSnapshot(GameAPI.readStatistics())
  ForeverAccountStatsDB = Sync.record(ForeverAccountStatsDB, character, snapshot, time())
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

SLASH_FOREVERACCOUNTSTATS1 = "/fas"
SlashCmdList.FOREVERACCOUNTSTATS = function()
  ForeverAccountStatsDB = Sync.ensureDB(ForeverAccountStatsDB)
  for _, line in ipairs(Listing.lines(ForeverAccountStatsDB, UnitGUID("player"), time())) do
    print(line)
  end
end
