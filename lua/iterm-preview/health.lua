local M = {}

local iterm = require("iterm-preview.iterm")
local state = require("iterm-preview.state")

local h = vim.health
local start = h.start or h.report_start
local ok = h.ok or h.report_ok
local warn = h.warn or h.report_warn
local err = h.error or h.report_error
local info = h.info or h.report_info

local function parse_version(v)
  local major, minor = v:match("^(%d+)%.(%d+)")
  if not major then return nil end
  return tonumber(major), tonumber(minor)
end

function M.check()
  start("iterm-preview")

  if vim.fn.has("mac") ~= 1 then
    err("not running on macOS; this plugin is macOS-only")
    return
  end
  ok("running on macOS")

  if vim.fn.executable("osascript") ~= 1 then
    err("osascript not found in PATH")
    return
  end
  ok("osascript available")

  local main = package.loaded["iterm-preview"]
  local opts = main and main.get_opts and main.get_opts() or nil
  local app = (opts and opts.iterm_app) or "iTerm"

  local version = iterm.check_iterm_version(app)
  if not version then
    err(
      string.format(
        "%s not installed, or AppleScript automation is not authorized "
          .. "(System Settings → Privacy & Security → Automation → enable your terminal → iTerm)",
        app
      )
    )
  else
    ok(app .. " version " .. version)
    local major, minor = parse_version(version)
    if major and (major < 3 or (major == 3 and minor < 5)) then
      warn("iTerm2 < 3.5 lacks Browser session support; the preview pane will not render HTML")
    end
  end

  if vim.env.LC_TERMINAL == "iTerm2" or vim.env.TERM_PROGRAM == "iTerm.app" then
    ok("Neovim is running inside iTerm2")
  else
    info(
      string.format(
        "Neovim does not appear to be running inside iTerm2 (TERM_PROGRAM=%s); "
          .. "the preview still works, but focus stays cleanest when nvim itself lives in iTerm",
        tostring(vim.env.TERM_PROGRAM)
      )
    )
  end

  if vim.fn.exists(":MarkdownPreview") == 2 then
    ok("iamcco/markdown-preview.nvim loaded")
  else
    warn(
      "markdown-preview.nvim not loaded; install it as a dependency "
        .. "(it loads per-filetype, so this can be normal outside a markdown buffer)"
    )
  end

  if opts then
    ok("setup() called")
    info("port: " .. tostring(vim.g.mkdp_port or opts.port))
    info("split direction: " .. opts.split.direction)
    info("profile: " .. (opts.profile or "<default>"))
    if opts.bridge_html and opts.bridge_html ~= "" then
      local dir = vim.fn.fnamemodify(opts.bridge_html, ":h")
      if vim.fn.isdirectory(dir) == 1 and vim.fn.filewritable(dir) == 2 then
        ok("bridge file directory is writable: " .. dir)
      else
        warn("bridge file directory not writable: " .. dir .. " (the preview pane will stay empty)")
      end
      info(
        string.format(
          "the '%s' profile must be Browser-type with Custom URL = file://%s",
          opts.profile or "Browser",
          opts.bridge_html
        )
      )
    else
      info("bridge_html disabled")
    end
  else
    warn("setup() not called yet; add require('iterm-preview').setup() to your config")
  end

  if state.has_session() then
    info(
      string.format(
        "active preview: buffer %s → %s",
        tostring(state.bufnr),
        tostring(state.last_url)
      )
    )
  end
end

return M
