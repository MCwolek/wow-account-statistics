-- Coin tokens exactly as GetStatistic returns them for money Statistics (single backslashes at runtime).
local M = {}

local function coin(name)
  return function(count)
    return count .. "|TInterface\\MoneyFrame\\UI-" .. name .. "Icon:0:0:2:0|t"
  end
end

M.gold = coin("Gold")
M.silver = coin("Silver")
M.copper = coin("Copper")

return M
