std = "lua51"
max_line_length = 120
exclude_files = { ".lua/", ".luarocks/", ".venv/" }

-- Globals the add-on defines or writes into.
globals = {
  "ForeverAccountStatisticsDB",
  "SLASH_FOREVERACCOUNTSTATS1",
  "SlashCmdList",
  "StaticPopupDialogs",
}

-- WoW API the add-on reads. Add entries as the code starts using them.
read_globals = {
  "AchievementFrame",
  "AchievementFrameStats",
  "ButtonFrameTemplate_HideButtonBar",
  "ButtonFrameTemplate_ShowPortrait",
  "C_AddOns",
  "C_ClassColor",
  "C_Texture",
  "C_Timer",
  "CreateAtlasMarkup",
  "CreateDataProvider",
  "CreateFromMixins",
  "CreateFont",
  "CreateFrame",
  "CreateScrollBoxListLinearView",
  "date",
  "GameTooltip",
  "GameTooltip_AddColoredDoubleLine",
  "GameTooltip_AddNormalLine",
  "GameTooltip_Hide",
  "GameTooltip_SetTitle",
  "GetAchievementInfo",
  "GetCategoryInfo",
  "GetCategoryNumAchievements",
  "GetClassAtlas",
  "GetCursorPosition",
  "GetLocale",
  "GetRealmName",
  "GetStatistic",
  "GetStatisticsCategoryList",
  "GRAY_FONT_COLOR",
  "GREEN_FONT_COLOR",
  "LIGHTGRAY_FONT_COLOR",
  "MenuStyle1Mixin",
  "MenuTemplates",
  "MenuVariants",
  "Minimap",
  "NORMAL_FONT_COLOR",
  "ScrollBoxConstants",
  "ScrollUtil",
  "STANDARD_TEXT_FONT",
  "StaticPopup_Show",
  "time",
  "UIParent",
  "UISpecialFrames",
  "UnitClass",
  "UnitFactionGroup",
  "UnitGUID",
  "UnitName",
}

files["spec/"] = { std = "+busted" }
