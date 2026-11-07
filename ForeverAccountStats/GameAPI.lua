-- Thin adapter: the only file that reads the game API for Sync. Returns plain data, holds no logic.
local _, ns = ...

local GameAPI = {}
ns.GameAPI = GameAPI

-- The logged-in Character as { guid, fullName, class }; class is the classFile, e.g. "WARRIOR".
function GameAPI.readCharacter()
  local firstName, surname = UnitName("player")
  local _, classFile = UnitClass("player")
  return {
    guid = UnitGUID("player"),
    fullName = ns.Sync.fullName(firstName, surname),
    class = classFile,
  }
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
