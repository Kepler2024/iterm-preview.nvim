local M = {}

M.defaults = {
  port = "8089",
  split = {
    direction = "right", -- right | left | below | above
  },
  auto_close = true,
  notify_level = vim.log.levels.INFO,
  iterm_app = "iTerm",
  profile = "Browser",
  filetypes = { "markdown" },
  bridge_html = "/tmp/iterm-preview.html",
  custom_script = nil,
}

local DIRECTIONS = { right = true, left = true, below = true, above = true }

-- Hand-rolled validation rather than vim.validate(): the table form of
-- vim.validate is deprecated from Neovim 0.11 and will eventually be removed,
-- and the per-argument form does not exist on 0.10. Plain checks work on every
-- supported version and give equally clear messages.
local function check(opts)
  local function bad(field, want, got)
    error(string.format("%s: expected %s, got %s", field, want, type(got)), 0)
  end

  if type(opts.port) ~= "string" and type(opts.port) ~= "number" then
    bad("port", "string|number", opts.port)
  end
  if type(opts.split) ~= "table" then bad("split", "table", opts.split) end
  if DIRECTIONS[opts.split.direction] ~= true then
    error(
      "split.direction: expected one of right|left|below|above, got "
        .. tostring(opts.split.direction),
      0
    )
  end
  if type(opts.auto_close) ~= "boolean" then bad("auto_close", "boolean", opts.auto_close) end
  if type(opts.notify_level) ~= "number" then bad("notify_level", "number", opts.notify_level) end
  if type(opts.iterm_app) ~= "string" then bad("iterm_app", "string", opts.iterm_app) end
  if opts.profile ~= nil and type(opts.profile) ~= "string" then
    bad("profile", "string|nil", opts.profile)
  end
  if type(opts.filetypes) ~= "table" then bad("filetypes", "table", opts.filetypes) end
  if opts.bridge_html ~= nil and type(opts.bridge_html) ~= "string" then
    bad("bridge_html", "string|nil", opts.bridge_html)
  end
  if opts.custom_script ~= nil and type(opts.custom_script) ~= "function" then
    bad("custom_script", "function|nil", opts.custom_script)
  end
end

function M.merge(user)
  local opts = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), user or {})
  check(opts)
  opts.port = tostring(opts.port)
  return opts
end

return M
