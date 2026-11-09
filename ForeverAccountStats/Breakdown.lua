-- Pure Breakdown of an Account Total: each Tracked Character's value of one Statistic, highest first.
local _, ns = ...

local Breakdown = {}
ns.Breakdown = Breakdown

-- Where a value goes: amounts first, then "--" (never happened), then "?" (missing from the Snapshot).
local RANK = { number = 1, money = 1, never = 2, missing = 3 }

-- How many Tracked Characters the Breakdown lists; the others are only counted.
local MAX_LINES = 5

-- Breakdown of the Statistic `statisticID` for `view`, { db, currentGUID, liveValues }, as { lines, more }: each
-- line { label, class, value } for one of the top MAX_LINES Tracked Characters, highest value first, and `more` the
-- count of the others. nil when the Statistic has no Account Total.
function Breakdown.build(statisticID, view)
  local byGUID, all = ns.Characters.statisticValues(view.db, view.currentGUID, view.liveValues)
  if ns.AccountTotals.compute(statisticID, all) == nil then
    return nil
  end
  local entries = {}
  for guid, character in pairs(view.db.characters) do
    local raw = byGUID[guid][statisticID]
    entries[#entries + 1] = {
      label = ns.Characters.displayName(character),
      class = character.class,
      value = ns.Values.display(raw),
      parsed = ns.Values.parse(raw),
    }
  end
  table.sort(entries, function(a, b)
    local rankA, rankB = RANK[a.parsed.kind], RANK[b.parsed.kind]
    if rankA ~= rankB then
      return rankA < rankB
    elseif rankA == RANK.number and a.parsed.amount ~= b.parsed.amount then
      return a.parsed.amount > b.parsed.amount
    end
    return a.label < b.label
  end)
  local lines = {}
  for i = 1, math.min(#entries, MAX_LINES) do
    local entry = entries[i]
    lines[i] = { label = entry.label, class = entry.class, value = entry.value }
  end
  return { lines = lines, more = #entries - #lines }
end
