local M = {}

local iterm = require("iterm-mdpreview.iterm")

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
  start("iterm-mdpreview")

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

  local version = iterm.check_iterm_version("iTerm")
  if not version then
    err("iTerm2 not installed, or AppleScript automation is not authorized (System Settings → Privacy & Security → Automation)")
  else
    ok("iTerm2 version " .. version)
    local major, minor = parse_version(version)
    if major and (major < 3 or (major == 3 and minor < 5)) then
      warn("iTerm2 < 3.5 lacks Browser session support; preview pane will not render HTML")
    end
  end

  if vim.fn.exists(":MarkdownPreview") == 2 then
    ok("iamcco/markdown-preview.nvim loaded")
  else
    warn("markdown-preview.nvim not loaded; install it as a dependency")
  end

  local main = package.loaded["iterm-mdpreview"]
  local opts = main and main.get_opts and main.get_opts() or nil
  if opts then
    ok("setup() called")
    info("port: " .. opts.port)
    info("split direction: " .. opts.split.direction)
    info("profile: " .. (opts.profile or "<default>"))
    info("bridge_html: " .. (opts.bridge_html or "<disabled>"))
  else
    warn("setup() not called yet — add require('iterm-mdpreview').setup() to your config")
  end
end

return M
