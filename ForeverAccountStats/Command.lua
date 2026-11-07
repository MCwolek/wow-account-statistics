-- Pure parsing of the /stats slash command.
local _, ns = ...

local Command = {}
ns.Command = Command

-- What the /stats arguments ask for, ignoring case and extra spaces: { action = "toggle" } with none (the
-- Statistics window), { action = "list" }, { action = "dump", statisticID = n }, or { action = "usage" } for
-- anything else.
function Command.parse(message)
  local words = {}
  for word in message:lower():gmatch("%S+") do
    words[#words + 1] = word
  end
  if #words == 0 then
    return { action = "toggle" }
  elseif words[1] == "list" and #words == 1 then
    return { action = "list" }
  end
  local statisticID = words[1] == "dump" and #words == 2 and tonumber(words[2]:match("^%d+$"))
  if statisticID then
    return { action = "dump", statisticID = statisticID }
  end
  return { action = "usage" }
end
