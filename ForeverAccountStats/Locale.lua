-- All user-facing text lives here: one table per locale, keyed like GetLocale().
local _, ns = ...

local Locale = {}
ns.Locale = Locale

local enUS = {
  ACCOUNT_TOTAL_COLUMN = "Account Total",
  ACCOUNT_TOTAL_LINE = "  Account Total: %s",
  ADDON_TITLE = "Account Statistics",
  -- Last line of an Account Total's Breakdown tooltip, counting the Tracked Characters it does not list.
  BREAKDOWN_MORE = "and %d more",
  CHARACTER_COLUMN = "Character",
  CHARACTER_WITH_RULESET = "%s (%s)",
  DAYS_AGO = "%d d ago",
  -- date() format of Last Synced's exact date and time; C89 strftime specifiers only.
  EXACT_DATE_TIME = "%Y-%m-%d %H:%M",
  -- The confirmation dialog of Forget, opened by the X on a dropdown entry; %s is the Full Name with its Ruleset.
  FORGET_CONFIRM = "Forget %s?\n\nIts Statistics will no longer count in the Account Totals. "
    .. "Logging it in again tracks it anew.",
  FORGET_ACCEPT = "Forget",
  FORGET_CANCEL = "Cancel",
  -- Tooltip of the X on a dropdown entry.
  FORGET_TOOLTIP = "Forget this Character",
  HOURS_AGO = "%d h ago",
  -- Tooltip of a Character in the window's dropdown; %s is the exact date and time.
  LAST_SYNC = "Last sync: %s",
  -- The Minimap button tooltip's line under the add-on's name: the mouse action, then what it does.
  MINIMAP_BUTTON_LEFT_CLICK = "Left Click:",
  MINIMAP_BUTTON_LEFT_CLICK_ACTION = "Open Account Statistics",
  -- Chat confirmations of /stats minimap; %s is the add-on's name.
  MINIMAP_BUTTON_HIDDEN = "%s: Minimap button hidden. /stats minimap shows it again.",
  MINIMAP_BUTTON_SHOWN = "%s: Minimap button shown. /stats minimap hides it.",
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
    .. "/stats dump <Statistic ID> shows one Statistic for each; /stats minimap hides or shows the Minimap button.",
}

-- German. Keep every placeholder of the English text, in the same order: Lua 5.1's string.format has no positional
-- arguments.
local deDE = {}

Locale.tables = {
  enUS = enUS,
  deDE = deDE,
}

-- The strings for a locale (a GetLocale() value), out of tables keyed like it:
-- that locale's own text, and English for every key its table lacks.
function Locale.pick(tables, locale)
  local strings = {}
  for key, text in pairs(tables.enUS) do
    strings[key] = text
  end
  for key, text in pairs(tables[locale] or {}) do
    strings[key] = text
  end
  return strings
end

-- The add-on follows the game's text language and has no language setting of its own (docs/adr/0004).
-- GetLocale() is the only game API this file calls: the text has to be in place before any other file loads.
ns.L = Locale.pick(Locale.tables, GetLocale())
