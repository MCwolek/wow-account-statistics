local addon = require("addon")

describe("MinimapRing", function()
  local MinimapRing = addon.loadFile("MinimapRing.lua", {}).MinimapRing

  describe("angleTowards", function()
    it("is the angle of a point around the Minimap's centre", function()
      assert.are.equal(0, MinimapRing.angleTowards(30, 0))
      assert.are.equal(90, MinimapRing.angleTowards(0, 30))
      assert.are.equal(180, MinimapRing.angleTowards(-30, 0))
      assert.are.equal(270, MinimapRing.angleTowards(0, -30))
      assert.are.equal(225, MinimapRing.angleTowards(-30, -30))
    end)
  end)

  describe("offset", function()
    local function assertOffset(expectedX, expectedY, angle)
      local x, y = MinimapRing.offset(angle, 100)
      assert.is_near(expectedX, x, 1e-9)
      assert.is_near(expectedY, y, 1e-9)
    end

    it("puts the button on the circle around the Minimap's centre at its angle", function()
      assertOffset(100, 0, 0)
      assertOffset(0, 100, 90)
      assertOffset(-100, 0, 180)
      assertOffset(0, -100, 270)
      assertOffset(-50 * math.sqrt(2), -50 * math.sqrt(2), 225)
    end)

    it("puts a dragged button where the cursor points", function()
      local angle = MinimapRing.angleTowards(-3, 4)
      assertOffset(-60, 80, angle)
    end)
  end)
end)
