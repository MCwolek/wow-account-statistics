-- Thin adapter: the only file that reads the game API. Returns plain data, holds no logic.
local _, ns = ...

local GameAPI = {}
ns.GameAPI = GameAPI

-- The logged-in Character as read: { guid, firstName, surname, classFile }; classFile is e.g. "WARRIOR".
function GameAPI.readPlayer()
  local firstName, surname = UnitName("player")
  local _, classFile = UnitClass("player")
  return {
    guid = UnitGUID("player"),
    firstName = firstName,
    surname = surname,
    classFile = classFile,
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
