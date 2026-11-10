std = "lua51"
max_line_length = 120
exclude_files = { ".lua/", ".luarocks/", ".venv/" }

-- Globals the add-on defines or writes into.
globals = {
  "ForeverAccountStatsDB",
  "SLASH_FOREVERACCOUNTSTATS1",
  "SlashCmdList",
  "StaticPopupDialogs",
}

-- WoW API the add-on reads. Add entries as the code starts using them.
read_globals = {
  "AchievementFrame",
  "AchievementFrameStats",
  "ButtonFrameTemplate_HideButtonBar",
  "ButtonFrameTemplate_HidePortrait",
  "C_AddOns",
  "C_ClassColor",
  "C_Timer",
  "CreateAtlasMarkup",
  "CreateDataProvider",
  "CreateFrame",
  "CreateScrollBoxListLinearView",
  "date",
  "GameTooltip",
  "GameTooltip_Hide",
  "GameTooltip_SetTitle",
  "GameFontHighlight_NoShadow",
  "GameFontNormal_NoShadow",
  "GetAchievementInfo",
  "GetCategoryInfo",
  "GetCategoryNumAchievements",
  "GetClassAtlas",
  "GetRealmName",
  "GetStatistic",
  "GetStatisticsCategoryList",
  "GRAY_FONT_COLOR",
  "MenuTemplates",
  "MenuVariants",
  "ScrollBoxConstants",
  "ScrollUtil",
  "StaticPopup_Show",
  "time",
  "UIParent",
  "UISpecialFrames",
  "UnitClass",
  "UnitGUID",
  "UnitName",
}

files["spec/"] = { std = "+busted" }
