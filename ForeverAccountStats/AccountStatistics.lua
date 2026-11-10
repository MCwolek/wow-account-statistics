-- Pure Statistic values across the Account: each Tracked Character's value, the Account Total and the Breakdown of
-- any Statistic. The one place where the logged-in Character's Live Values replace its saved Snapshot.
local _, ns = ...

local AccountStatistics = {}
AccountStatistics.__index = AccountStatistics
ns.AccountStatistics = AccountStatistics

-- Peak Statistics, hand-picked by Statistic ID: largest single amounts, skill levels and counts of one
-- Character's current standing, where a sum means nothing. The game's flags cannot tell them apart from counters.
local PEAK_STATISTICS = {
  [189] = true, -- Largest heal cast
  [193] = true, -- Largest hit dealt
  [527] = true, -- Largest hit received
  [829] = true, -- Largest heal received
  [331] = true, -- Most expensive bid on auction
  [332] = true, -- Most expensive auction sold
  [334] = true, -- Most gold ever owned
  [281] = true, -- First Aid skill
  [1519] = true, -- Fishing skill
  [1524] = true, -- Cooking skill
  [1527] = true, -- Highest Alchemy skill
  [1532] = true, -- Highest Blacksmithing skill
  [1535] = true, -- Highest Enchanting skill
  [1536] = true, -- Highest Leatherworking skill
  [1537] = true, -- Highest Mining skill
  [1538] = true, -- Highest Herbalism skill
  [1539] = true, -- Highest Inscription skill
  [1541] = true, -- Highest Skinning skill
  [1542] = true, -- Highest Tailoring skill
  [1544] = true, -- Highest Engineering skill
  [377] = true, -- Most factions at Exalted
  [378] = true, -- Most factions at Revered or higher
  [529] = true, -- Most factions at Honored or higher
  [931] = true, -- Total factions encountered
  [1337] = true, -- Different creature types killed
  -- Account-wide (#8): every Character reads the same value, 4, though none has a faction at Exalted, so it is
  -- not one Character's own (likely counted from other game modes on the Account). A sum would multiply it.
  [926] = true, -- Most Horde factions at Exalted
  [1466] = true, -- Most Alliance factions at Exalted
  -- Collections may be account-wide on this client too; unverified, as they read "--" on every Character so far.
  [338] = true, -- Vanity pets owned
  [339] = true, -- Mounts owned
}

-- Statistics without an Account Total, hand-picked by Statistic ID.
local STATISTICS_WITHOUT_ACCOUNT_TOTAL = {
  -- Average Statistics: each is a per-Character average per day, so a sum overstates (a new Character's first day
  -- counts in full) and a highest value means little.
  [95] = true, -- Average quests completed per day
  [753] = true, -- Average gold earned per day
  -- Text Statistics (DB2 flag MAX_USED): a count with a label, e.g. "62 (Beasts)". They read "--" until the first
  -- count, which must not show as an Account Total of "--".
  [1125] = true, -- Bandage used most
  [1336] = true, -- Creature type killed the most
  [1339] = true, -- Mage portal taken most
  [1458] = true, -- Continent with the most Honorable Kills
  [1489] = true, -- Continent with the most Killing Blows
  [1716] = true, -- Battleground with the most Killing Blows
  [1719] = true, -- Battleground with the most Honorable Kills
}

-- Which kind a total takes when Characters' values differ: "--" says nothing about the kind (a zero money
-- Statistic also reads "--"), so any number or money value decides it.
local KIND_RANK = { never = 1, number = 2, money = 3 }

-- Account Total of the Statistic over every Tracked Character's values (`valuesByGUID`), as a parsed value (see
-- Values.parse): the sum, or the highest value for a Peak Statistic. "--" counts as 0; values without the Statistic
-- are left out, and the total is "missing" when none has it. nil when the Statistic has no Account Total: one of
-- STATISTICS_WITHOUT_ACCOUNT_TOTAL, or any value is shaped like text.
local function computeTotal(statisticID, valuesByGUID)
  if STATISTICS_WITHOUT_ACCOUNT_TOTAL[statisticID] then
    return nil
  end
  local kind, total = nil, 0
  for _, values in pairs(valuesByGUID) do
    local value = ns.Values.parse(values[statisticID])
    if value.kind == "text" then
      return nil -- a text value no hand-picked ID covers still has no total
    elseif value.kind ~= "missing" then
      if PEAK_STATISTICS[statisticID] then
        total = math.max(total, value.amount)
      else
        total = total + value.amount
      end
      if kind == nil or KIND_RANK[value.kind] > KIND_RANK[kind] then
        kind = value.kind
      end
    end
  end
  if kind == nil then
    return { kind = "missing" }
  end
  return { kind = kind, amount = total }
end

-- The Statistic values of every Tracked Character in `db` at the time `now`: its saved Snapshot, except that the
-- logged-in Character (`currentGUID`) counts with its Live Values (`liveValues`) when they are given. Without Live
-- Values every Character reads its saved Snapshot; /stats dump omits them. A Character without a Snapshot has no
-- values.
function AccountStatistics.new(db, currentGUID, now, liveValues)
  local valuesByGUID = {}
  for guid, character in pairs(db.characters) do
    if guid == currentGUID and liveValues then
      valuesByGUID[guid] = liveValues
    else
      valuesByGUID[guid] = character.snapshot or {}
    end
  end
  return setmetatable({ roster = ns.Roster.of(db, currentGUID, now), valuesByGUID = valuesByGUID }, AccountStatistics)
end

-- Display string of the Tracked Character `guid`'s value of the Statistic (see Values.display): the game's own
-- string, or L.MISSING_VALUE when its values lack the Statistic or `guid` is no Tracked Character.
function AccountStatistics:value(guid, statisticID)
  local values = guid and self.valuesByGUID[guid] or {}
  return ns.Values.display(values[statisticID])
end

-- Display string of the Statistic's Account Total (see Values.format), or L.NO_ACCOUNT_TOTAL when it has none.
function AccountStatistics:accountTotal(statisticID)
  local total = computeTotal(statisticID, self.valuesByGUID)
  if total == nil then
    return ns.L.NO_ACCOUNT_TOTAL
  end
  return ns.Values.format(total)
end

-- Every Tracked Character's value of the Statistic, in Roster order (see Roster.of): { label, class, value, parsed,
-- position }, with `value` its display string, `parsed` the same value parsed (see Values.parse) and `position` its
-- place in the Roster.
local function characterEntries(self, statisticID)
  local entries = {}
  for position, character in ipairs(self.roster) do
    local raw = self.valuesByGUID[character.guid][statisticID]
    entries[position] = {
      label = character.label,
      class = character.class,
      value = ns.Values.display(raw),
      parsed = ns.Values.parse(raw),
      position = position,
    }
  end
  return entries
end

-- The line a Character entry shows: { label, class, value }.
local function lineOf(entry)
  return { label = entry.label, class = entry.class, value = entry.value }
end

-- Every Tracked Character's value of the Statistic as { label, class, value }, in Roster order: the Character's
-- Full Name and Ruleset, its class (see Roster.of), and its value's display string (see value).
function AccountStatistics:characterValues(statisticID)
  local lines = {}
  for i, entry in ipairs(characterEntries(self, statisticID)) do
    lines[i] = lineOf(entry)
  end
  return lines
end

-- Sort order of the parsed value kinds in a Breakdown (see Values.parse): amounts first, then a Statistic that never
-- happened, then one missing from the values.
local BREAKDOWN_ORDER = { number = 1, money = 1, never = 2, missing = 3 }

local function isAmount(value)
  return value.kind == "number" or value.kind == "money"
end

-- How many Tracked Characters a Breakdown lists; the others are only counted.
local BREAKDOWN_LINES = 5

-- Breakdown of the Statistic as { lines, more }: each line { label, class, value } for one of the top
-- BREAKDOWN_LINES Tracked Characters, highest value first, "--" and then "?" last, equal values in Roster order;
-- `more` the count of the others. nil when the Statistic has no Account Total, or no Character's values have it.
function AccountStatistics:breakdown(statisticID)
  local total = computeTotal(statisticID, self.valuesByGUID)
  if total == nil or total.kind == "missing" then
    return nil
  end
  local entries = characterEntries(self, statisticID)
  table.sort(entries, function(a, b)
    local orderA, orderB = BREAKDOWN_ORDER[a.parsed.kind], BREAKDOWN_ORDER[b.parsed.kind]
    if orderA ~= orderB then
      return orderA < orderB
    elseif isAmount(a.parsed) and a.parsed.amount ~= b.parsed.amount then
      return a.parsed.amount > b.parsed.amount
    end
    return a.position < b.position
  end)
  local lines = {}
  for i = 1, math.min(#entries, BREAKDOWN_LINES) do
    lines[i] = lineOf(entries[i])
  end
  return { lines = lines, more = #entries - #lines }
end
