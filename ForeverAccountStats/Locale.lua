-- All user-facing text lives here, in English. Translations are a later feature.
local _, ns = ...

ns.L = {
  ACCOUNT_TOTAL_COLUMN = "Account Total",
  ACCOUNT_TOTAL_LINE = "  Account Total: %s",
  ADDON_TITLE = "Forever Account Stats",
  -- Last line of an Account Total's Breakdown tooltip, counting the Tracked Characters it does not list.
  BREAKDOWN_MORE = "and %d more",
  CHARACTER_COLUMN = "Character",
  CHARACTER_WITH_RULESET = "%s (%s)",
  DAYS_AGO = "%d d ago",
  -- date() format of Last Synced's exact date and time; C89 strftime specifiers only.
  EXACT_DATE_TIME = "%Y-%m-%d %H:%M",
  HOURS_AGO = "%d h ago",
  -- Tooltip of a Character in the window's dropdown; %s is the exact date and time.
  LAST_SYNC = "Last sync: %s",
  MINUTES_AGO = "%d min ago",
  -- Marker for a Statistic missing from a Character's Snapshot, e.g. one taken by an older version.
  MISSING_VALUE = "?",
  -- Account Total of a Statistic that has never happened on any Character, matching the game's own display for zero.
  NEVER_HAPPENED = "--",
  -- Account Total shown for Text and Average Statistics, which have none.
  NO_ACCOUNT_TOTAL = "—",
  NOW = "now",
  -- Placeholder in the window's search box, which narrows the list to Statistics by name.
  SEARCH_PLACEHOLDER = "Search Statistics",
  STATISTIC_COLUMN = "Statistic",
  STATISTIC_HEADER = "%s: %s (%d)",
  STATISTIC_LINE = "  %s - %s",
  -- The button on the default UI's Statistics tab that opens the window.
  STATISTICS_TAB_BUTTON = "Account Stats",
  TRACKED_CHARACTERS_HEADER = "%s: Tracked Characters (%d)",
  TRACKED_CHARACTER_LINE = "  %s - %s",
  UNKNOWN_STATISTIC = "Unknown Statistic",
  USAGE = "%s: /stats opens the Statistics window; /stats list lists Tracked Characters; "
    .. "/stats dump <Statistic ID> shows one Statistic for each.",
}
