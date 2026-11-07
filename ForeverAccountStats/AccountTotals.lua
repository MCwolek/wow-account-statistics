-- Pure Account Total logic: combines one Statistic's values from the Snapshots of all Tracked Characters.
local _, ns = ...

local AccountTotals = {}
ns.AccountTotals = AccountTotals

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
  [926] = true, -- Most Horde factions at Exalted
  [1466] = true, -- Most Alliance factions at Exalted
  [931] = true, -- Total factions encountered
  [1337] = true, -- Different creature types killed
  -- Collections may be account-wide on this client, so every Character would count the same ones (see #8).
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

-- Account Total of one Statistic over a list of Snapshots, as a parsed value (see Values.parse): the sum, or
-- the highest value for a Peak Statistic. "--" counts as 0; a Snapshot without the Statistic is left out, and
-- the total is "missing" when no Snapshot has it. nil when the Statistic has no Account Total: a Text or Average
-- Statistic, or any Snapshot reads a value shaped like text.
function AccountTotals.compute(statisticID, snapshots)
  if NO_ACCOUNT_TOTAL[statisticID] then
    return nil
  end
  local kind, total = nil, 0
  for _, snapshot in ipairs(snapshots) do
    local value = ns.Values.parse(snapshot[statisticID])
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

-- Display string of the Account Total; NO_ACCOUNT_TOTAL when the Statistic has none.
function AccountTotals.display(statisticID, snapshots)
  local total = AccountTotals.compute(statisticID, snapshots)
  if total == nil then
    return ns.L.NO_ACCOUNT_TOTAL
  end
  return ns.Values.format(total)
end
