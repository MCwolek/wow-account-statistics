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
