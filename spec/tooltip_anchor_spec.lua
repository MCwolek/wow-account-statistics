local addon = require("addon")

describe("TooltipAnchor", function()
  local TooltipAnchor = addon.loadFile("TooltipAnchor.lua", {}).TooltipAnchor
  local WIDTH, HEIGHT = 1200, 900

  describe("towardScreenCentre", function()
    it("hangs the tooltip below a button in the top half of the screen", function()
      assert.are.same({ "TOP", "BOTTOM" }, { TooltipAnchor.towardScreenCentre(600, 800, WIDTH, HEIGHT) })
    end)

    it("stands the tooltip above a button in the bottom half of the screen", function()
      assert.are.same({ "BOTTOM", "TOP" }, { TooltipAnchor.towardScreenCentre(600, 100, WIDTH, HEIGHT) })
    end)

    it("lines up the right edges for a button in the right third, as the Minimap's", function()
      assert.are.same({ "TOPRIGHT", "BOTTOMRIGHT" }, { TooltipAnchor.towardScreenCentre(1100, 800, WIDTH, HEIGHT) })
    end)

    it("lines up the left edges for a button in the left third", function()
      assert.are.same({ "BOTTOMLEFT", "TOPLEFT" }, { TooltipAnchor.towardScreenCentre(100, 100, WIDTH, HEIGHT) })
    end)

    it("centres the tooltip on a button in the middle third", function()
      assert.are.same({ "TOP", "BOTTOM" }, { TooltipAnchor.towardScreenCentre(401, 451, WIDTH, HEIGHT) })
      assert.are.same({ "BOTTOM", "TOP" }, { TooltipAnchor.towardScreenCentre(799, 450, WIDTH, HEIGHT) })
    end)
  end)
end)
