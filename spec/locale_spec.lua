local addon = require("addon")

describe("Locale.pick", function()
  local Locale = addon.loadFile("Locale.lua", {}).Locale

  local tables = {
    enUS = { TITLE = "Statistics", CANCEL = "Cancel" },
    deDE = { TITLE = "Statistiken" },
  }

  it("gives an English client the English strings", function()
    assert.are.same({ TITLE = "Statistics", CANCEL = "Cancel" }, Locale.pick(tables, "enUS"))
  end)

  it("gives a German client the German strings, and English for any the translation lacks", function()
    assert.are.same({ TITLE = "Statistiken", CANCEL = "Cancel" }, Locale.pick(tables, "deDE"))
  end)

  it("gives English to a client in a language without a translation", function()
    assert.are.same({ TITLE = "Statistics", CANCEL = "Cancel" }, Locale.pick(tables, "frFR"))
    assert.are.same({ TITLE = "Statistics", CANCEL = "Cancel" }, Locale.pick(tables, "enGB"))
  end)
end)

describe("ns.L", function()
  -- Loads Locale.lua the way a client in the given language does, putting the specs' GetLocale back even when
  -- loading fails, so one failure does not switch every later spec's language.
  local function loadIn(locale)
    local gameGetLocale = _G.GetLocale
    ---@diagnostic disable-next-line: duplicate-set-field
    _G.GetLocale = function()
      return locale
    end
    local loaded, result = pcall(addon.loadFile, "Locale.lua", {})
    _G.GetLocale = gameGetLocale
    if not loaded then
      error(result, 0)
    end
    return result
  end

  it("is the German text on a German client, English where it has none", function()
    local ns = loadIn("deDE")
    local tables = ns.Locale.tables
    for key, english in pairs(tables.enUS) do
      assert.are.equal(tables.deDE[key] or english, ns.L[key], key)
    end
  end)

  it("is the English text on a client in a language without a translation", function()
    local ns = loadIn("frFR")
    assert.are.same(ns.Locale.tables.enUS, ns.L)
  end)
end)

describe("Locale tables", function()
  -- Keys whose text is a date() format, not a string.format one: a translation may reorder its specifiers.
  local DATE_FORMATS = { EXACT_DATE_TIME = true }

  -- The % specifiers of a text in order, leaving out the escaped "%%".
  local function placeholders(text)
    local found = {}
    for placeholder in text:gsub("%%%%", ""):gmatch("%%[-+ #0]*%d*%.?%d*%a") do
      found[#found + 1] = placeholder
    end
    return found
  end

  local function sorted(list)
    local copy = { unpack(list) }
    table.sort(copy)
    return copy
  end

  -- What is wrong with a translation measured against English, one line per problem.
  local function translationProblems(english, translation)
    local problems = {}
    for key, text in pairs(translation) do
      local englishText = english[key]
      if englishText == nil then
        problems[#problems + 1] = key .. " is not in English"
      else
        local expected, actual = placeholders(englishText), placeholders(text)
        if DATE_FORMATS[key] then
          expected, actual = sorted(expected), sorted(actual)
        end
        if table.concat(expected, " ") ~= table.concat(actual, " ") then
          problems[#problems + 1] = key .. " has " .. table.concat(actual, " ") .. " where English has "
            .. table.concat(expected, " ")
        end
      end
    end
    table.sort(problems)
    return problems
  end

  it("catches a translation whose keys or placeholders stray from English", function()
    local english = {
      HEADER = "%s: %s (%d)",
      MORE = "and %d more",
      SHARE = "%d%% of %s",
      EXACT_DATE_TIME = "%Y-%m-%d %H:%M",
    }
    local translation = {
      HEADER = "%s (%d): %s",
      MORE = "und %d weitere",
      SHARE = "%d %% von %s",
      EXACT_DATE_TIME = "%d.%m.%Y %H:%M",
      EXTRA = "Extra",
    }
    assert.are.same({
      "EXTRA is not in English",
      "HEADER has %s %d %s where English has %s %s %d",
    }, translationProblems(english, translation))
  end)

  local tables = addon.loadFile("Locale.lua", {}).Locale.tables

  it("hold only non-empty text, in every language", function()
    for locale, strings in pairs(tables) do
      for key, text in pairs(strings) do
        assert.are.equal("string", type(text), locale .. " " .. key)
        assert.is_true(#text > 0, locale .. " " .. key)
      end
    end
  end)

  it("translate only English keys, keeping their placeholders in English order", function()
    for locale, strings in pairs(tables) do
      assert.are.same({}, translationProblems(tables.enUS, strings), locale)
    end
  end)

  -- The slash commands a text names, sorted: "/stats" alone or with one of its sub-commands.
  local SUB_COMMANDS = { list = true, dump = true, minimap = true }
  local function slashCommands(text)
    local found = {}
    for word in text:gmatch("/stats ?(%a*)") do
      found[#found + 1] = SUB_COMMANDS[word] and "/stats " .. word or "/stats"
    end
    table.sort(found)
    return found
  end

  it("name the same slash commands as English, untranslated", function()
    for locale, strings in pairs(tables) do
      for key, text in pairs(strings) do
        assert.are.same(slashCommands(tables.enUS[key]), slashCommands(text), locale .. " " .. key)
      end
    end
  end)

  it("spell out the add-on's name only in its title, so a rename touches one string", function()
    local addonName = tables.enUS.ADDON_TITLE
    for locale, strings in pairs(tables) do
      for key, text in pairs(strings) do
        if key ~= "ADDON_TITLE" then
          assert.is_nil(text:find(addonName, 1, true), locale .. " " .. key)
        end
      end
    end
  end)

  describe("German", function()
    -- Keys German leaves to English: the add-on's name stays "Account Statistics" in every language.
    local LEFT_IN_ENGLISH = { ADDON_TITLE = true }

    it("has its own text for every English key but the add-on's name", function()
      local missing = {}
      for key in pairs(tables.enUS) do
        if not LEFT_IN_ENGLISH[key] and tables.deDE[key] == nil then
          missing[#missing + 1] = key
        end
      end
      table.sort(missing)
      assert.are.same({}, missing)
      for key in pairs(LEFT_IN_ENGLISH) do
        assert.is_nil(tables.deDE[key], key)
      end
    end)
  end)
end)
