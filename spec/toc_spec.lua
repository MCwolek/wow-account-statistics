local addon = require("addon")

describe("ForeverAccountStats.toc", function()
  local metadata, files = addon.readToc()

  it("targets the WoW: Forever client", function()
    assert.are.equal("16001", metadata.Interface)
  end)

  it("describes the add-on in German for a German client", function()
    assert.is_string(metadata["Notes-deDE"])
    assert.are_not.equal(metadata.Notes, metadata["Notes-deDE"])
  end)

  it("lists only files that exist", function()
    assert.is_true(#files > 0)
    for _, path in ipairs(files) do
      local handle = io.open(addon.DIR .. "/" .. path, "r")
      assert.is_not_nil(handle, path .. " is listed in the .toc but missing")
      handle:close()
    end
  end)
end)
