local addon = require("addon")

describe("Command.parse", function()
  local Command = addon.loadFile("Command.lua", {}).Command

  it("toggles the Statistics window with no arguments", function()
    assert.are.same({ action = "toggle" }, Command.parse(""))
    assert.are.same({ action = "toggle" }, Command.parse("   "))
  end)

  it("lists Tracked Characters, ignoring case and extra spaces", function()
    assert.are.same({ action = "list" }, Command.parse("list"))
    assert.are.same({ action = "list" }, Command.parse("  LIST "))
  end)

  it("dumps one Statistic by ID, ignoring case and extra spaces", function()
    assert.are.same({ action = "dump", statisticID = 60 }, Command.parse("dump 60"))
    assert.are.same({ action = "dump", statisticID = 328 }, Command.parse("  DUMP   328 "))
  end)

  it("shows or hides the Minimap button, ignoring case and extra spaces", function()
    assert.are.same({ action = "minimap" }, Command.parse("minimap"))
    assert.are.same({ action = "minimap" }, Command.parse("  MiniMap "))
  end)

  it("shows usage for anything else", function()
    assert.are.same({ action = "usage" }, Command.parse("list all"))
    assert.are.same({ action = "usage" }, Command.parse("dump"))
    assert.are.same({ action = "usage" }, Command.parse("dump deaths"))
    assert.are.same({ action = "usage" }, Command.parse("dump 60 61"))
    assert.are.same({ action = "usage" }, Command.parse("minimap hide"))
    assert.are.same({ action = "usage" }, Command.parse("help"))
  end)
end)
