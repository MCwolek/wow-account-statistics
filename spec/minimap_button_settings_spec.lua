local addon = require("addon")

describe("MinimapButtonSettings", function()
  local MinimapButtonSettings = addon.loadFile("MinimapButtonSettings.lua", {}).MinimapButtonSettings

  describe("shown", function()
    it("is shown when nothing is saved yet", function()
      assert.is_true(MinimapButtonSettings.isShown(nil))
      assert.is_true(MinimapButtonSettings.isShown({}))
    end)

    it("hides a shown button and shows a hidden one", function()
      local hidden = MinimapButtonSettings.shownToggled(nil)
      assert.is_false(MinimapButtonSettings.isShown(hidden))
      assert.is_true(MinimapButtonSettings.isShown(MinimapButtonSettings.shownToggled(hidden)))
    end)
  end)

  describe("angle", function()
    it("sits at the Minimap's lower left when no angle is saved yet", function()
      assert.are.equal(225, MinimapButtonSettings.angle(nil))
      assert.are.equal(225, MinimapButtonSettings.angle({ hidden = true }))
      assert.are.equal(225, MinimapButtonSettings.angle({ angle = "north" }))
    end)

    it("restores the angle it was moved to, keeping it hidden or shown", function()
      local moved = MinimapButtonSettings.moved(MinimapButtonSettings.shownToggled(nil), 90)
      assert.are.equal(90, MinimapButtonSettings.angle(moved))
      assert.is_false(MinimapButtonSettings.isShown(moved))
    end)

    it("keeps the angle it was moved to when hidden or shown", function()
      local hidden = MinimapButtonSettings.shownToggled(MinimapButtonSettings.moved(nil, 10))
      assert.are.equal(10, MinimapButtonSettings.angle(hidden))
    end)

    it("saves an angle within one turn", function()
      assert.are.equal(40, MinimapButtonSettings.angle(MinimapButtonSettings.moved(nil, 400)))
      assert.are.equal(270, MinimapButtonSettings.angle(MinimapButtonSettings.moved(nil, -90)))
    end)
  end)
end)
