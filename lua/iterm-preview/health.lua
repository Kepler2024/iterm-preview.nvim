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

-- Reads the iTerm2 Browser profile's start URL straight from iTerm's prefs so
-- checkhealth can compare it to the bridge path the plugin actually writes. A
-- single stray character here (a trailing dot copied along with a sentence, a
-- leftover space) points the pane at a file that does not exist, and the only
-- visible symptom is a blank pane that never loads. Uses only macOS built-ins
-- (defaults, plutil) plus vim.json; no external dependencies.
--
-- Returns status, url where status is "found" | "not_found" | "unknown".
local function profile_initial_url(profile_name)
  local out = vim.fn.system({
    "bash",
    "-c",
    'defaults export com.googlecode.iterm2 - | plutil -extract "New Bookmarks" json -o - -',
  })
  if vim.v.shell_error ~= 0 or out == nil or out == "" then return "unknown", nil end
  local okj, arr = pcall(vim.json.decode, out)
  if not okj or type(arr) ~= "table" then return "unknown", nil end
  for _, b in ipairs(arr) do
    if type(b) == "table" and b.Name == profile_name then return "found", b["Initial URL"] end
  end
  return "not_found", nil
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
    local port = vim.g.mkdp_port
    if port == nil or port == "" then port = opts.port end
    if port == nil or port == "" then
      info("port: auto (mkdp picks a free port each run)")
    else
      info("port: " .. tostring(port))
    end
    info("split direction: " .. opts.split.direction)
    info("profile: " .. (opts.profile or "<default>"))
    if opts.bridge_html and opts.bridge_html ~= "" then
      local dir = vim.fn.fnamemodify(opts.bridge_html, ":h")
      if vim.fn.isdirectory(dir) == 1 and vim.fn.filewritable(dir) == 2 then
        ok("bridge file directory is writable: " .. dir)
      else
        warn("bridge file directory not writable: " .. dir .. " (the preview pane will stay empty)")
      end
      local profile = opts.profile or "Browser"
      local expected = "file://" .. opts.bridge_html
      local status, url = profile_initial_url(profile)
      if status == "found" then
        if url == expected then
          ok(string.format("profile '%s' URL points at the bridge (%s)", profile, expected))
        elseif type(url) == "string" and (url:gsub("[%.%s]+$", "")) == expected then
          err(
            string.format(
              "profile '%s' URL is %q, which has a stray trailing character, so the pane loads a "
                .. "file that does not exist (blank pane). Set it to exactly: %s",
              profile,
              url,
              expected
            )
          )
        else
          err(
            string.format(
              "profile '%s' URL is %q but should be exactly: %s",
              profile,
              tostring(url),
              expected
            )
          )
        end
      elseif status == "not_found" then
        warn(
          string.format(
            "no iTerm profile named '%s' found; create a Browser-type profile whose URL is exactly: %s",
            profile,
            expected
          )
        )
      else
        info(
          string.format(
            "set the '%s' Browser profile's URL to exactly: %s (could not read iTerm prefs to verify)",
            profile,
            expected
          )
        )
      end
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
