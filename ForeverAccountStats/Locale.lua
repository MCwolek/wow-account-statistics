-- All user-facing text lives here, in English. Translations are a later feature.
local _, ns = ...

ns.L = {
  ADDON_TITLE = "Forever Account Stats",
  CHARACTER_WITH_RULESET = "%s (%s)",
  DAYS_AGO = "%d d ago",
  HOURS_AGO = "%d h ago",
  MINUTES_AGO = "%d min ago",
  -- Marker for a Statistic missing from a Character's Snapshot, e.g. one taken by an older version.
  MISSING_VALUE = "?",
  -- Account Total of a Statistic that has never happened on any Character, matching the game's own display for zero.
  NEVER_HAPPENED = "--",
  -- Account Total shown for Text and Average Statistics, which have none.
  NO_ACCOUNT_TOTAL = "—",
  NOW = "now",
  TRACKED_CHARACTERS_HEADER = "%s: Tracked Characters (%d)",
  TRACKED_CHARACTER_LINE = "  %s - %s",
}
