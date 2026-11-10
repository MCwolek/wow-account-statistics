local addon = require("addon")

local function loadCharacterDropdown()
  local ns = addon.loadFile("Locale.lua", {})
  return addon.loadFile("CharacterDropdown.lua", ns).CharacterDropdown
end

describe("CharacterDropdown.entries", function()
  local CharacterDropdown = loadCharacterDropdown()

  it("lists the logged-in Character first, then the others in Roster order", function()
    local roster = {
      { guid = "A", isCurrent = false },
      { guid = "B", isCurrent = false },
      { guid = "C", isCurrent = true },
      { guid = "D", isCurrent = false },
    }
    assert.are.same({
      { guid = "C", isCurrent = true },
      { guid = "A", isCurrent = false },
      { guid = "B", isCurrent = false },
      { guid = "D", isCurrent = false },
    }, CharacterDropdown.entries(roster))
  end)
end)

describe("CharacterDropdown.lastSyncedTooltip", function()
  local CharacterDropdown = loadCharacterDropdown()

  it("gives an entry's Last Synced as a date and time, through the game's date()", function()
    -- Local time, as the game's date() formats it.
    local lastSynced = os.time({ year = 2026, month = 11, day = 5, hour = 7, min = 5, sec = 30 })
    assert.are.equal("Last sync: 2026-11-05 07:05",
      CharacterDropdown.lastSyncedTooltip({ lastSynced = lastSynced }, os.date))
  end)
end)
