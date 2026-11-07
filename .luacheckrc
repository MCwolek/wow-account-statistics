std = "lua51"
max_line_length = 120
exclude_files = { ".lua/", ".luarocks/", ".venv/" }

-- Globals the add-on defines or writes into.
globals = {
  "ForeverAccountStatsDB",
  "SLASH_FOREVERACCOUNTSTATS1",
  "SlashCmdList",
}

-- WoW API the add-on reads. Add entries as the code starts using them.
read_globals = {
  "CreateFrame",
  "GetAchievementInfo",
  "GetCategoryNumAchievements",
  "GetRealmName",
  "GetStatistic",
  "GetStatisticsCategoryList",
  "UnitClass",
  "UnitGUID",
  "UnitName",
  "time",
}

files["spec/"] = { std = "+busted" }
