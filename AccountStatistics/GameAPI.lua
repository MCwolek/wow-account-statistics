-- Thin adapter: reads the game API and returns plain data, holds no logic. The Statistics window's frames live in
-- the other adapter, Window.lua.
local addonName, ns = ...

local GameAPI = {}
ns.GameAPI = GameAPI

-- The add-on's version, as its .toc's Version field reads: the release tag, e.g. "1.0.0", stamped in by the packager.
function GameAPI.addOnVersion()
  return C_AddOns.GetAddOnMetadata(addonName, "Version")
end

-- The logged-in Character as read: { guid, firstName, surname, realmName, classFile, factionGroup }.
-- realmName is e.g. "CAMWOW EU4 Realm 5 PvE"; classFile is e.g. "WARRIOR"; factionGroup is e.g. "Horde",
-- "Alliance" or "Neutral".
function GameAPI.readPlayer()
  local firstName, surname = UnitName("player")
  local _, classFile = UnitClass("player")
  return {
    guid = UnitGUID("player"),
    firstName = firstName,
    surname = surname,
    realmName = GetRealmName(),
    classFile = classFile,
    factionGroup = UnitFactionGroup("player"),
  }
end

-- GUID of the logged-in Character.
function GameAPI.playerGUID()
  return UnitGUID("player")
end

-- Current time in seconds (Unix epoch), as time() returns it.
function GameAPI.now()
  return time()
end

-- Every Statistic of the logged-in Character as { id = statisticID, value = displayString }.
function GameAPI.readStatistics()
  local readings = {}
  for _, categoryID in ipairs(GetStatisticsCategoryList()) do
    local count = GetCategoryNumAchievements(categoryID, true)
    for index = 1, count do
      local statisticID = GetAchievementInfo(categoryID, index)
      if statisticID then
        readings[#readings + 1] = { id = statisticID, value = GetStatistic(statisticID) }
      end
    end
  end
  return readings
end

-- `t` (Unix epoch seconds) in local time through the game's date(), e.g. format "%Y-%m-%d %H:%M".
function GameAPI.formatDate(format, t)
  return date(format, t)
end

-- The default Statistics panel's Categories and Statistics, read as it reads them, in game order:
-- { categories = { { id, name, parentID }, ... }, statistics = { [categoryID] = { { id, name, skip }, ... } } }.
-- parentID is -1 for a root Category; `skip` marks a Statistic the default panel does not show.
function GameAPI.readCategories()
  local categories, statistics = {}, {}
  for _, categoryID in ipairs(GetStatisticsCategoryList()) do
    local name, parentID = GetCategoryInfo(categoryID)
    categories[#categories + 1] = { id = categoryID, name = name, parentID = parentID }
    local list = {}
    for index = 1, GetCategoryNumAchievements(categoryID) do
      local _, skip, statisticID = GetStatistic(categoryID, index)
      if statisticID == nil then
        -- A client without the (categoryID, index) form: read the ID as the Snapshot does, and skip nothing.
        statisticID, skip = GetAchievementInfo(categoryID, index), false
      end
      if statisticID then
        local _, statisticName = GetAchievementInfo(statisticID)
        list[#list + 1] = { id = statisticID, name = statisticName, skip = skip and true or false }
      end
    end
    statistics[categoryID] = list
  end
  return { categories = categories, statistics = statistics }
end

-- Name of a Statistic, or nil when the game knows no such ID.
function GameAPI.statisticName(statisticID)
  local _, name = GetAchievementInfo(statisticID)
  return name
end
