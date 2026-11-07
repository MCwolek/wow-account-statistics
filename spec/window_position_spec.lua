local addon = require("addon")

local function loadWindowPosition()
  return addon.loadFile("WindowPosition.lua", {}).WindowPosition
end

describe("WindowPosition", function()
  local WindowPosition = loadWindowPosition()

  it("restores the anchor it saved", function()
    local saved = WindowPosition.save("TOPLEFT", "BOTTOMLEFT", 120.5, -40)
    assert.are.same({ "TOPLEFT", "BOTTOMLEFT", 120.5, -40 }, { WindowPosition.anchor(saved) })
  end)

  it("centres the window when no position is saved yet", function()
    assert.are.same({ "CENTER", "CENTER", 0, 0 }, { WindowPosition.anchor(nil) })
  end)

  it("centres the window when the saved position is incomplete", function()
    assert.are.same({ "CENTER", "CENTER", 0, 0 }, { WindowPosition.anchor({ point = "TOPLEFT", x = 10 }) })
  end)
end)
