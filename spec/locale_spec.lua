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
  -- Loads Locale.lua the way a client in the given language does.
  local function loadIn(locale)
    local gameGetLocale = _G.GetLocale
    ---@diagnostic disable-next-line: duplicate-set-field
    _G.GetLocale = function()
      return locale
    end
    local ns = addon.loadFile("Locale.lua", {})
    _G.GetLocale = gameGetLocale
    return ns
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
