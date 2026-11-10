-- Pure Window Session of the Statistics window: what the window remembers from opening to closing, and the rows it
-- shows for it.
local _, ns = ...

local WindowSession = {}
ns.WindowSession = WindowSession

-- A copy of the open window with the fields that `change()` returns set. A closed window stays as it is, without
-- calling `change`: emptying the search box on closing, for one, lands here after the window has closed.
local function changed(session, change)
  if not session.list then
    return session
  end
  local copy = {}
  for key, value in pairs(session) do
    copy[key] = value
  end
  for key, value in pairs(change()) do
    copy[key] = value
  end
  return copy
end

-- The closed window over the Category tree `tree`.
function WindowSession.new(tree)
  return { tree = tree }
end

-- The window just opened, counting the logged-in Character's Live Values `liveValues`: every Category expanded, on
-- the logged-in Character, with no search.
function WindowSession.opened(session, liveValues)
  return { tree = session.tree, list = ns.ListState.new(session.tree), liveValues = liveValues }
end

-- The window closed: it forgets the expanded Categories, the chosen Character, the search and the Live Values.
function WindowSession.closed(session)
  return WindowSession.new(session.tree)
end

-- Whether the window is open.
function WindowSession.isOpen(session)
  return session.list ~= nil
end

-- The window with the Character `guid` chosen in the dropdown.
function WindowSession.characterChosen(session, guid)
  return changed(session, function()
    return { chosen = guid }
  end)
end

-- The window with the Category `categoryID` expanded when it was collapsed and collapsed when it was expanded (see
-- ListState.toggled).
function WindowSession.categoryToggled(session, categoryID)
  return changed(session, function()
    return { list = ns.ListState.toggled(session.list, categoryID) }
  end)
end

-- The window with the search box reading `text` (see ListState.searched).
function WindowSession.searched(session, text)
  return changed(session, function()
    return { list = ns.ListState.searched(session.list, text) }
  end)
end

-- The window counting the logged-in Character's Live Values `liveValues`, just read.
function WindowSession.liveValuesRead(session, liveValues)
  return changed(session, function()
    return { liveValues = liveValues }
  end)
end

-- GUID of the Character whose values the window shows: the one chosen in the dropdown while `db`, the
-- SavedVariables, still tracks it, or else the logged-in Character, `currentGUID`.
function WindowSession.chosenCharacter(session, db, currentGUID)
  if session.chosen and db.characters[session.chosen] then
    return session.chosen
  end
  return currentGUID
end

-- Every Tracked Character's values in `db`, the logged-in one's (`currentGUID`) its Live Values.
local function accountStatistics(session, db, currentGUID)
  return ns.AccountStatistics.new(db, currentGUID, session.liveValues)
end

-- The rows the window shows (see Rows.build), from `db`, the SavedVariables, with `currentGUID` the logged-in
-- Character.
function WindowSession.rows(session, db, currentGUID)
  local statistics = accountStatistics(session, db, currentGUID)
  local chosen = WindowSession.chosenCharacter(session, db, currentGUID)
  return ns.Rows.build(ns.ListState.visibleRows(session.list), statistics, chosen)
end

-- The Breakdown of the Statistic `statisticID` (see AccountStatistics:breakdown), counting the Live Values.
function WindowSession.breakdown(session, db, currentGUID, statisticID)
  return accountStatistics(session, db, currentGUID):breakdown(statisticID)
end
