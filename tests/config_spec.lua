local config = require("iterm-mdpreview.config")

describe("config.merge", function()
  it("returns defaults when user opts is nil", function()
    local opts = config.merge(nil)
    assert.are.equal("8089", opts.port)
    assert.are.equal("right", opts.split.direction)
    assert.are.equal("Browser", opts.profile)
    assert.is_true(opts.auto_close)
  end)

  it("deep-merges user overrides", function()
    local opts = config.merge({ split = { direction = "below" } })
    assert.are.equal("below", opts.split.direction)
    -- preserves siblings
    assert.is_nil(opts.split.size)
  end)

  it("coerces port to string", function()
    local opts = config.merge({ port = 9000 })
    assert.are.equal("9000", opts.port)
  end)

  it("rejects invalid split direction", function()
    assert.has_error(function() config.merge({ split = { direction = "diagonal" } }) end)
  end)

  it("rejects out-of-range split size", function()
    assert.has_error(function() config.merge({ split = { size = 0 } }) end)
    assert.has_error(function() config.merge({ split = { size = 101 } }) end)
  end)

  it("accepts a custom_script function", function()
    local opts = config.merge({ custom_script = function(url) return url end })
    assert.is_function(opts.custom_script)
  end)
end)
