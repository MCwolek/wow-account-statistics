local addon = require("addon")

describe("MinimapButtonSettings", function()
  local MinimapButtonSettings = addon.loadFile("MinimapButtonSettings.lua", {}).MinimapButtonSettings

  describe("shown", function()
    it("is shown when nothing is saved yet", function()
      assert.is_true(MinimapButtonSettings.isShown(nil))
      assert.is_true(MinimapButtonSettings.isShown({}))
    end)

    it("hides a shown button and shows a hidden one", function()
      local hidden = MinimapButtonSettings.withShownToggled(nil)
      assert.is_false(MinimapButtonSettings.isShown(hidden))
      assert.is_true(MinimapButtonSettings.isShown(MinimapButtonSettings.withShownToggled(hidden)))
    end)
  end)

  describe("angle", function()
    it("sits at the Minimap's lower left when no angle is saved yet", function()
      assert.are.equal(225, MinimapButtonSettings.angle(nil))
      assert.are.equal(225, MinimapButtonSettings.angle({ hidden = true }))
      assert.are.equal(225, MinimapButtonSettings.angle({ angle = "north" }))
    end)

    it("moves a hidden button, keeping it hidden", function()
      local moved = MinimapButtonSettings.moved(MinimapButtonSettings.withShownToggled(nil), 90)
      assert.are.equal(90, MinimapButtonSettings.angle(moved))
      assert.is_false(MinimapButtonSettings.isShown(moved))
    end)

    it("keeps a moved button's angle once it is hidden", function()
      local hidden = MinimapButtonSettings.withShownToggled(MinimapButtonSettings.moved(nil, 10))
      assert.are.equal(10, MinimapButtonSettings.angle(hidden))
    end)

    it("saves an angle within one turn", function()
      assert.are.equal(40, MinimapButtonSettings.angle(MinimapButtonSettings.moved(nil, 400)))
      assert.are.equal(270, MinimapButtonSettings.angle(MinimapButtonSettings.moved(nil, -90)))
    end)
  end)
end)
