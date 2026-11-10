local addon = require("addon")

local function loadWindowSession()
  local ns = {}
  for _, path in ipairs({
    "Locale.lua", "Values.lua", "Roster.lua", "AccountStatistics.lua", "CategoryTree.lua", "ListState.lua",
    "RowLayout.lua", "Rows.lua", "WindowSession.lua",
  }) do
    addon.loadFile(path, ns)
  end
  return ns.WindowSession, ns.CategoryTree
end

local CURRENT, OTHER = "Player-1-0000AAAA", "Player-1-0000BBBB"

-- The rows the window shows, one line each: a Category with its +/- ("-" expanded), a Statistic with the chosen
-- Character's value and the Account Total.
local function shown(rows)
  local lines = {}
  for _, row in ipairs(rows) do
    if row.kind == "category" then
      lines[#lines + 1] = (row.expanded and "- " or "+ ") .. row.name
    else
      lines[#lines + 1] = row.name .. ": " .. row.value .. " / " .. row.total
    end
  end
  return lines
end

describe("WindowSession", function()
  local WindowSession, CategoryTree = loadWindowSession()

  local tree = CategoryTree.build({
    { id = 130, name = "Character", parentID = -1 },
    { id = 131, name = "Wealth", parentID = 130 },
    { id = 141, name = "Combat", parentID = -1 },
  }, {
    [130] = { { id = 60, name = "Total deaths" } },
    [131] = { { id = 328, name = "Total gold acquired" } },
    [141] = { { id = 193, name = "Largest hit dealt" } },
  })

  local db = {
    characters = {
      [CURRENT] = { fullName = "Calgan Blackbeard", snapshot = { [60] = "2", [328] = "10", [193] = "40" } },
      [OTHER] = { fullName = "Mira Stonehand", snapshot = { [60] = "3", [328] = "5", [193] = "90" } },
    },
  }
  local liveValues = { [60] = "4", [328] = "12", [193] = "50" }

  local function opened()
    return WindowSession.opened(WindowSession.new(tree), liveValues)
  end

  it("opens with every Category expanded, on the logged-in Character, with no search", function()
    local session = opened()
    assert.are.same({
      "- Character",
      "Total deaths: 4 / 7",
      "- Wealth",
      "Total gold acquired: 12 / 17",
      "- Combat",
      "Largest hit dealt: 50 / 90",
    }, shown(WindowSession.rows(session, db, CURRENT)))
    assert.are.equal(CURRENT, WindowSession.chosenCharacter(session, db, CURRENT))
  end)

  it("shows the values of the Character chosen in the dropdown", function()
    local session = WindowSession.characterChosen(opened(), OTHER)
    assert.are.same({
      "- Character",
      "Total deaths: 3 / 7",
      "- Wealth",
      "Total gold acquired: 5 / 17",
      "- Combat",
      "Largest hit dealt: 90 / 90",
    }, shown(WindowSession.rows(session, db, CURRENT)))
    assert.are.equal(OTHER, WindowSession.chosenCharacter(session, db, CURRENT))
  end)

  it("falls back to the logged-in Character when the chosen one is no longer tracked", function()
    local session = WindowSession.characterChosen(opened(), OTHER)
    local forgotten = { characters = { [CURRENT] = db.characters[CURRENT] } }
    assert.are.same({
      "- Character",
      "Total deaths: 4 / 4",
      "- Wealth",
      "Total gold acquired: 12 / 12",
      "- Combat",
      "Largest hit dealt: 50 / 50",
    }, shown(WindowSession.rows(session, forgotten, CURRENT)))
    assert.are.equal(CURRENT, WindowSession.chosenCharacter(session, forgotten, CURRENT))
  end)

  it("keeps the whole tree's expanded Categories through a search for when it is cleared", function()
    local session = WindowSession.categoryToggled(opened(), 141)
    session = WindowSession.searched(session, "gold")
    assert.are.same({
      "- Character",
      "- Wealth",
      "Total gold acquired: 12 / 17",
    }, shown(WindowSession.rows(session, db, CURRENT)))

    session = WindowSession.categoryToggled(session, 130)
    assert.are.same({ "+ Character" }, shown(WindowSession.rows(session, db, CURRENT)))

    session = WindowSession.searched(session, "")
    assert.are.same({
      "- Character",
      "Total deaths: 4 / 7",
      "- Wealth",
      "Total gold acquired: 12 / 17",
      "+ Combat",
    }, shown(WindowSession.rows(session, db, CURRENT)))
  end)

  it("shows the logged-in Character's Live Values read since opening", function()
    local session = WindowSession.categoryToggled(opened(), 130)
    session = WindowSession.liveValuesRead(session, { [60] = "4", [328] = "12", [193] = "75" })
    assert.are.same({
      "+ Character",
      "- Combat",
      "Largest hit dealt: 75 / 90",
    }, shown(WindowSession.rows(session, db, CURRENT)))
  end)

  it("forgets the expanded Categories, the chosen Character and the search on closing", function()
    local session = WindowSession.categoryToggled(opened(), 141)
    session = WindowSession.characterChosen(session, OTHER)
    session = WindowSession.searched(session, "gold")
    session = WindowSession.closed(session)
    assert.is_false(WindowSession.isOpen(session))

    session = WindowSession.opened(session, liveValues)
    assert.is_true(WindowSession.isOpen(session))
    assert.are.same(shown(WindowSession.rows(opened(), db, CURRENT)), shown(WindowSession.rows(session, db, CURRENT)))
    assert.are.equal(CURRENT, WindowSession.chosenCharacter(session, db, CURRENT))
  end)

  it("stays closed when the search box is emptied after closing", function()
    local session = WindowSession.searched(WindowSession.closed(WindowSession.searched(opened(), "gold")), "")
    assert.is_false(WindowSession.isOpen(session))
  end)

  it("counts the logged-in Character's Live Values in a Statistic's Breakdown", function()
    assert.are.same({
      lines = {
        { label = "Calgan Blackbeard", value = "4" },
        { label = "Mira Stonehand", value = "3" },
      },
      more = 0,
    }, WindowSession.breakdown(opened(), db, CURRENT, 60))
  end)
end)
