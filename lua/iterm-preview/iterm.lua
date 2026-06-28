local M = {}

local log = require("iterm-preview.log")

local function plugin_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  return vim.fn.fnamemodify(source, ":h:h:h")
end

local function script_path(name) return plugin_root() .. "/scripts/" .. name end

local function run(cmd, timeout_ms)
  local ok, result = pcall(
    function() return vim.system(cmd, { text = true }):wait(timeout_ms or 5000) end
  )
  if not ok then
    log.error("vim.system failed: " .. tostring(result))
    return nil
  end
  if result.code ~= 0 then
    local stderr = (result.stderr or ""):gsub("[\r\n]+", " ")
    log.error(string.format("osascript exited %d: %s", result.code, stderr))
    return nil
  end
  return vim.trim(result.stdout or "")
end

local HTML_ESCAPES = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;" }

local function html_escape(s) return (s:gsub('[&<>"]', HTML_ESCAPES)) end

-- iTerm's AppleScript dictionary can't navigate a Browser session to an
-- arbitrary URL, so we drop a tiny meta-refresh page at `path` and let the
-- profile's Custom URL (file://<path>) bounce the pane to `url`. Writing the
-- file here rather than in AppleScript keeps URL escaping in Lua and off the
-- shell.
local function write_bridge(path, url)
  local html = string.format(
    '<!DOCTYPE html><meta http-equiv="refresh" content="0; url=%s">',
    html_escape(url)
  )
  local f, ferr = io.open(path, "w")
  if not f then return false, ferr end
  f:write(html)
  f:close()
  return true
end

function M.open_split(url, opts)
  if opts.custom_script then
    local script = opts.custom_script(url)
    return run({ "osascript", "-e", script })
  end

  if opts.bridge_html and opts.bridge_html ~= "" then
    local okb, berr = write_bridge(opts.bridge_html, url)
    if not okb then
      log.error("could not write bridge file " .. opts.bridge_html .. ": " .. tostring(berr))
      return nil
    end
  end

  -- 15s timeout: the very first run blocks on the macOS Automation permission
  -- prompt until the user clicks Allow.
  return run({
    "osascript",
    script_path("open_split.applescript"),
    opts.split.direction,
    opts.profile or "",
    opts.iterm_app or "iTerm",
  }, 15000)
end

function M.close_split(session_id, opts)
  if not session_id or session_id == "" then return end
  run({
    "osascript",
    script_path("close_split.applescript"),
    session_id,
    opts.iterm_app or "iTerm",
  })
end

function M.check_iterm_version(app)
  app = app or "iTerm"
  local cmd = { "osascript", "-e", string.format('tell application "%s" to version', app) }
  local result = vim.system(cmd, { text = true }):wait(2000)
  if result.code ~= 0 then return nil end
  return vim.trim(result.stdout or "")
end

return M
