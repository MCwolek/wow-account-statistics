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
local NO_ACCOUNT_TOTAL = {
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

-- Account Total of the Statistic over every Tracked Character's values, as a parsed value (see Values.parse): the
-- sum, or the highest value for a Peak Statistic. "--" counts as 0; values without the Statistic are left out, and
-- the total is "missing" when none has it. nil when the Statistic has no Account Total: a Text or Average Statistic,
-- or any value is shaped like text.
local function computeTotal(statisticID, allValues)
  if NO_ACCOUNT_TOTAL[statisticID] then
    return nil
  end
  local kind, total = nil, 0
  for _, values in ipairs(allValues) do
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

-- The Statistic values of every Tracked Character in `db`: its saved Snapshot, or for the logged-in Character
-- (`currentGUID`) its Live Values (`liveValues`) when given. The Statistics window passes both. /stats dump passes
-- neither, so it shows every Character's saved Snapshot: it reports what the add-on has saved.
-- A Character without a Snapshot has no values.
function AccountStatistics.new(db, currentGUID, liveValues)
  local byGUID, all = {}, {}
  for guid, character in pairs(db.characters) do
    local values
    if guid == currentGUID and liveValues then
      values = liveValues
    else
      values = character.snapshot or {}
    end
    byGUID[guid] = values
    all[#all + 1] = values
  end
  return setmetatable({ db = db, byGUID = byGUID, all = all }, AccountStatistics)
end

-- Display string of the Tracked Character `guid`'s value of the Statistic (see Values.display): the game's own
-- string, or MISSING_VALUE when its values lack the Statistic or `guid` is no Tracked Character.
function AccountStatistics:value(guid, statisticID)
  local values = guid and self.byGUID[guid] or {}
  return ns.Values.display(values[statisticID])
end

-- Display string of the Statistic's Account Total (see Values.format), or NO_ACCOUNT_TOTAL when it has none.
function AccountStatistics:accountTotal(statisticID)
  local total = computeTotal(statisticID, self.all)
  if total == nil then
    return ns.L.NO_ACCOUNT_TOTAL
  end
  return ns.Values.format(total)
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
-- BREAKDOWN_LINES Tracked Characters, highest value first, "--" and then "?" last, equal values by name; `more` the
-- count of the others. nil when the Statistic has no Account Total, or no Character's values have it.
function AccountStatistics:breakdown(statisticID)
  local total = computeTotal(statisticID, self.all)
  if total == nil or total.kind == "missing" then
    return nil
  end
  local entries = {}
  for guid, character in pairs(self.db.characters) do
    local raw = self.byGUID[guid][statisticID]
    entries[#entries + 1] = {
      label = ns.Characters.displayName(character),
      class = character.class,
      value = ns.Values.display(raw),
      parsed = ns.Values.parse(raw),
    }
  end
  table.sort(entries, function(a, b)
    local orderA, orderB = BREAKDOWN_ORDER[a.parsed.kind], BREAKDOWN_ORDER[b.parsed.kind]
    if orderA ~= orderB then
      return orderA < orderB
    elseif isAmount(a.parsed) and a.parsed.amount ~= b.parsed.amount then
      return a.parsed.amount > b.parsed.amount
    end
    return a.label < b.label
  end)
  local lines = {}
  for i = 1, math.min(#entries, BREAKDOWN_LINES) do
    local entry = entries[i]
    lines[i] = { label = entry.label, class = entry.class, value = entry.value }
  end
  return { lines = lines, more = #entries - #lines }
end
