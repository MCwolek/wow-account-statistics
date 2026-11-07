local addon = require("addon")
local coins = require("coins")
local gold, silver, copper = coins.gold, coins.silver, coins.copper

local function loadValues()
  local ns = addon.loadFile("Locale.lua", {})
  return addon.loadFile("Values.lua", ns).Values
end

describe("Values.parse", function()
  local Values = loadValues()

  it("reads a plain number", function()
    assert.are.same({ kind = "number", amount = 115 }, Values.parse("115"))
  end)

  it("reads -- as never happened, worth 0", function()
    assert.are.same({ kind = "never", amount = 0 }, Values.parse("--"))
  end)

  it("reads a coin string from a real Snapshot as copper", function()
    -- Spelled out once, so the coin helpers stay tied to the real string.
    assert.are.same(
      { kind = "money", amount = 727 },
      Values.parse(
        "7|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t 27|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
      )
    )
    assert.are.same({ kind = "money", amount = 16439 }, Values.parse(gold(1) .. " " .. silver(64) .. " " .. copper(39)))
  end)

  it("reads coin strings that omit zero denominations", function()
    assert.are.same({ kind = "money", amount = 50012 }, Values.parse(gold(5) .. " " .. copper(12)))
    assert.are.same({ kind = "money", amount = 3 }, Values.parse(copper(3)))
    assert.are.same({ kind = "money", amount = 20000 }, Values.parse(gold(2)))
  end)

  it("reads numbers and gold with thousands separators of any client locale", function()
    assert.are.same({ kind = "number", amount = 1234 }, Values.parse("1,234"))
    assert.are.same({ kind = "number", amount = 1234567 }, Values.parse("1.234.567"))
    assert.are.same({ kind = "money", amount = 12340005 }, Values.parse(gold("1,234") .. " " .. copper(5)))
  end)

  it("reads a number whose separators are not thousands groups as text", function()
    assert.are.same({ kind = "text", text = "1.5" }, Values.parse("1.5"))
  end)

  it("reads a count with a label as text", function()
    assert.are.same({ kind = "text", text = "62 (Beasts)" }, Values.parse("62 (Beasts)"))
    assert.are.same({ kind = "text", text = "115 (Eastern Kingdoms)" }, Values.parse("115 (Eastern Kingdoms)"))
  end)

  it("reads anything else that is not a number, -- or coin string as text", function()
    assert.are.same({ kind = "text", text = "1g 64s 39c" }, Values.parse("1g 64s 39c"))
    assert.are.same({ kind = "text", text = "5 " .. gold(1) }, Values.parse("5 " .. gold(1)))
    assert.are.same({ kind = "text", text = "" }, Values.parse(""))
  end)

  it("reads a Statistic missing from the Snapshot as missing", function()
    assert.are.same({ kind = "missing" }, Values.parse(nil))
  end)
end)

describe("Values.isNeverHappened", function()
  local Values = loadValues()

  it("is true only for the game's -- sentinel", function()
    assert.is_true(Values.isNeverHappened("--"))
    assert.is_false(Values.isNeverHappened("0"))
    assert.is_false(Values.isNeverHappened("27"))
    assert.is_false(Values.isNeverHappened(nil))
  end)

  it("does not follow the add-on's own display marker", function()
    local ns = addon.loadFile("Locale.lua", {})
    ns.L.NEVER_HAPPENED = "never"
    local relabelled = addon.loadFile("Values.lua", ns).Values
    assert.is_true(relabelled.isNeverHappened("--"))
    assert.is_false(relabelled.isNeverHappened("never"))
    assert.are.same({ kind = "never", amount = 0 }, relabelled.parse("--"))
  end)
end)

describe("Values.display", function()
  local Values = loadValues()

  it("shows a Character's value as the game does", function()
    assert.are.equal("--", Values.display("--"))
    assert.are.equal("62 (Beasts)", Values.display("62 (Beasts)"))
    assert.are.equal(silver(7) .. " " .. copper(27), Values.display(silver(7) .. " " .. copper(27)))
  end)

  it("shows the game's display string unchanged, even where a total would be written differently", function()
    assert.are.equal("1,234", Values.display("1,234"))
    assert.are.equal(gold("1.234") .. " " .. copper(5), Values.display(gold("1.234") .. " " .. copper(5)))
    local largeIcons = "3|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:2:0|t"
    assert.are.equal(largeIcons, Values.display(largeIcons))
  end)

  it("shows ? for a Statistic missing from the Character's Snapshot", function()
    assert.are.equal("?", Values.display(nil))
  end)
end)

describe("Values.format", function()
  local Values = loadValues()

  it("writes money with coin icons exactly as GetStatistic does", function()
    -- Spelled out once, so the coin helpers stay tied to the real string.
    assert.are.equal(
      "1|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t 64|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t "
        .. "39|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t",
      Values.format({ kind = "money", amount = 16439 })
    )
    assert.are.equal(silver(7) .. " " .. copper(27), Values.format({ kind = "money", amount = 727 }))
  end)

  it("leaves out zero denominations of money", function()
    assert.are.equal(gold(5) .. " " .. copper(12), Values.format({ kind = "money", amount = 50012 }))
    assert.are.equal(gold(2), Values.format({ kind = "money", amount = 20000 }))
    assert.are.equal(copper(3), Values.format({ kind = "money", amount = 3 }))
    assert.are.equal(gold(1234) .. " " .. silver(56), Values.format({ kind = "money", amount = 12345600 }))
  end)

  it("writes zero money as zero copper, like the default UI", function()
    assert.are.equal(copper(0), Values.format({ kind = "money", amount = 0 }))
  end)

  it("writes a number as plain digits", function()
    assert.are.equal("1234", Values.format({ kind = "number", amount = 1234 }))
  end)

  it("writes never happened as --", function()
    assert.are.equal("--", Values.format({ kind = "never", amount = 0 }))
  end)

  it("writes a missing Statistic as ?", function()
    assert.are.equal("?", Values.format({ kind = "missing" }))
  end)

  it("writes text unchanged", function()
    assert.are.equal("62 (Beasts)", Values.format({ kind = "text", text = "62 (Beasts)" }))
  end)

  it("writes back every real display string it parses", function()
    for _, display in ipairs({
      "--",
      "115",
      "62 (Beasts)",
      silver(14) .. " " .. copper(56),
      gold(1) .. " " .. silver(30) .. " " .. copper(39),
    }) do
      assert.are.equal(display, Values.format(Values.parse(display)))
    end
  end)
end)
