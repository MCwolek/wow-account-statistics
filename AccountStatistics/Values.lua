-- Pure parsing and formatting of Statistic values. GetStatistic returns display strings, never numbers.
local _, ns = ...

local Values = {}
ns.Values = Values

-- What GetStatistic returns for a Statistic that has never happened (zero). The game's sentinel, not the add-on's
-- display marker: that is L.NEVER_HAPPENED and may differ.
local NEVER_HAPPENED_RAW = "--"

-- Whether a raw value from GetStatistic says the Statistic has never happened.
function Values.isNeverHappened(raw)
  return raw == NEVER_HAPPENED_RAW
end

local COPPER_PER_COIN = { Gold = 10000, Silver = 100, Copper = 1 }

-- Integer from digits with optional thousands separators, or nil. Separators come in groups of three, as "," or
-- "." depending on the client locale; "1.5" is not an integer.
local function parseGroupedInteger(text)
  if text:match("^%d+$") then
    return tonumber(text)
  end
  local head = text:match("^%d%d?%d?")
  if head == nil or #text == #head or text:sub(#head + 1):gsub("[,.]%d%d%d", "") ~= "" then
    return nil
  end
  return tonumber((text:gsub("[,.]", "")))
end

-- One coin token: "<digits>|TInterface\MoneyFrame\UI-<Gold|Silver|Copper>Icon:<args>|t".
local COIN_TOKEN = "([%d,.]+)|TInterface\\MoneyFrame\\UI%-(%a+)Icon:[^|]*|t"

-- Copper in a coin string, or nil when the string holds anything besides coin tokens and spaces.
local function parseMoney(raw)
  local copper, coins = 0, 0
  local rest = raw:gsub(COIN_TOKEN, function(digits, coin)
    local value, count = COPPER_PER_COIN[coin], parseGroupedInteger(digits)
    if value and count then
      copper = copper + count * value
      coins = coins + 1
      return ""
    end
  end)
  if coins == 0 or rest:match("%S") then
    return nil
  end
  return copper
end

-- Parsed value of one raw display string from GetStatistic: { kind, amount } for "number", "money" (in copper)
-- and "never" ("--", worth 0); { kind, text } for "text"; { kind = "missing" } when the Snapshot has no value (nil).
function Values.parse(raw)
  if raw == nil then
    return { kind = "missing" }
  end
  if Values.isNeverHappened(raw) then
    return { kind = "never", amount = 0 }
  end
  local copper = parseMoney(raw)
  if copper then
    return { kind = "money", amount = copper }
  end
  local number = parseGroupedInteger(raw)
  if number then
    return { kind = "number", amount = number }
  end
  return { kind = "text", text = raw }
end

-- Same token format as GetStatistic and Blizzard's GetMoneyString (GOLD_AMOUNT_TEXTURE and friends).
-- The texture paths are not localized.
local COIN_FORMAT = "%d|TInterface\\MoneyFrame\\UI-%sIcon:0:0:2:0|t"

-- Coin string like GetMoneyString(copper): zero denominations left out, zero itself as "0" copper.
local function formatMoney(copper)
  local coins = {}
  local gold, silver = math.floor(copper / 10000), math.floor(copper / 100) % 100
  copper = copper % 100
  if gold > 0 then
    coins[#coins + 1] = COIN_FORMAT:format(gold, "Gold")
  end
  if silver > 0 then
    coins[#coins + 1] = COIN_FORMAT:format(silver, "Silver")
  end
  if copper > 0 or #coins == 0 then
    coins[#coins + 1] = COIN_FORMAT:format(copper, "Copper")
  end
  return table.concat(coins, " ")
end

-- Display string of a parsed value, as the default UI would show it.
function Values.format(value)
  if value.kind == "money" then
    return formatMoney(value.amount)
  elseif value.kind == "number" then
    return ("%d"):format(value.amount)
  elseif value.kind == "never" then
    return ns.L.NEVER_HAPPENED
  elseif value.kind == "missing" then
    return ns.L.MISSING_VALUE
  end
  return value.text
end

-- Display string of one Character's Statistic value: the game's own string unchanged, exactly as the default UI
-- shows it, or MISSING_VALUE when `raw` is nil (missing from the Snapshot).
function Values.display(raw)
  if raw == nil then
    return ns.L.MISSING_VALUE
  end
  return raw
end
