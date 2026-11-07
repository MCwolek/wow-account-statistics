-- All user-facing text lives here, in English. Translations are a later feature.
local _, ns = ...

ns.L = {
  ACCOUNT_TOTAL_LINE = "  Account Total: %s",
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
  STATISTIC_HEADER = "%s: %s (%d)",
  STATISTIC_LINE = "  %s - %s",
  TRACKED_CHARACTERS_HEADER = "%s: Tracked Characters (%d)",
  TRACKED_CHARACTER_LINE = "  %s - %s",
  UNKNOWN_STATISTIC = "Unknown Statistic",
  USAGE = "%s: /stats lists Tracked Characters; /stats dump <Statistic ID> shows one Statistic for each.",
}
