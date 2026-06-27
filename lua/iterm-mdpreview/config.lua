local M = {}

M.defaults = {
  port = "8089",
  split = {
    direction = "right",
    size = nil,
  },
  auto_close = true,
  reuse_split = false,
  notify_level = vim.log.levels.INFO,
  iterm_app = "iTerm",
  profile = "Browser",
  filetypes = { "markdown" },
  bridge_html = "/tmp/iterm-mdpreview.html",
  custom_script = nil,
}

local DIRECTIONS = { right = true, left = true, below = true, above = true }

local function validate(opts)
  vim.validate({
    port = { opts.port, { "string", "number" } },
    split = { opts.split, "table" },
    auto_close = { opts.auto_close, "boolean" },
    reuse_split = { opts.reuse_split, "boolean" },
    notify_level = { opts.notify_level, "number" },
    iterm_app = { opts.iterm_app, "string" },
    profile = { opts.profile, { "string", "nil" } },
    filetypes = { opts.filetypes, "table" },
    bridge_html = { opts.bridge_html, { "string", "nil" } },
    custom_script = { opts.custom_script, { "function", "nil" } },
  })
  vim.validate({
    ["split.direction"] = {
      opts.split.direction,
      function(v) return DIRECTIONS[v] == true end,
      "one of right|left|below|above",
    },
    ["split.size"] = {
      opts.split.size,
      function(v) return v == nil or (type(v) == "number" and v > 0 and v <= 100) end,
      "nil or number in (0, 100]",
    },
  })
end

function M.merge(user)
  local opts = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), user or {})
  validate(opts)
  opts.port = tostring(opts.port)
  return opts
end

return M
