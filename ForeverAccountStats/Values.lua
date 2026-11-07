-- Pure parsing and formatting of Statistic values. GetStatistic returns display strings, never numbers.
local _, ns = ...

local Values = {}
ns.Values = Values

local COPPER_PER_COIN = { Gold = 10000, Silver = 100, Copper = 1 }

-- Integer from a run of digits, or nil. Thousands separators are allowed in groups of three, as "," or "."
-- depending on the client locale; "1.5" is not an integer.
local function toInteger(digits)
  if digits:match("^%d+$") then
    return tonumber(digits)
  end
  local head = digits:match("^%d%d?%d?")
  if head == nil or #digits == #head or digits:sub(#head + 1):gsub("[,.]%d%d%d", "") ~= "" then
    return nil
  end
  return tonumber((digits:gsub("[,.]", "")))
end

-- One coin token: "<digits>|TInterface\MoneyFrame\UI-<Gold|Silver|Copper>Icon:<args>|t".
local COIN_TOKEN = "([%d,.]+)|TInterface\\MoneyFrame\\UI%-(%a+)Icon:[^|]*|t"

-- Copper in a coin string, or nil when the string holds anything besides coin tokens and spaces.
local function parseMoney(display)
  local copper, coins = 0, 0
  local rest = display:gsub(COIN_TOKEN, function(digits, coin)
    local value, count = COPPER_PER_COIN[coin], toInteger(digits)
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

-- Parsed value of one display string: { kind, amount } for "number", "money" (in copper) and "never" ("--",
-- worth 0); { kind, text } for "text"; { kind = "missing" } when the Snapshot has no value (nil).
function Values.parse(display)
  if display == nil then
    return { kind = "missing" }
  end
  if display == "--" then
    return { kind = "never", amount = 0 }
  end
  local copper = parseMoney(display)
  if copper then
    return { kind = "money", amount = copper }
  end
  local number = toInteger(display)
  if number then
    return { kind = "number", amount = number }
  end
  return { kind = "text", text = display }
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

-- Display string of one Character's raw Statistic value (nil when missing from its Snapshot).
function Values.display(display)
  return Values.format(Values.parse(display))
end
