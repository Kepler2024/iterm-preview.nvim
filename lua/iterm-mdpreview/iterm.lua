local M = {}

local log = require("iterm-mdpreview.log")

local function plugin_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  return vim.fn.fnamemodify(source, ":h:h:h")
end

local function script_path(name)
  return plugin_root() .. "/scripts/" .. name
end

local function run(cmd, timeout_ms)
  local ok, result = pcall(function()
    return vim.system(cmd, { text = true }):wait(timeout_ms or 5000)
  end)
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

function M.open_split(url, opts)
  if opts.custom_script then
    local script = opts.custom_script(url)
    return run({ "osascript", "-e", script })
  end

  return run({
    "osascript",
    script_path("open_split.applescript"),
    url,
    opts.split.direction,
    opts.profile or "",
    opts.bridge_html or "",
    opts.iterm_app or "iTerm",
  })
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
  local result = vim.system(
    { "osascript", "-e", string.format('tell application "%s" to version', app) },
    { text = true }
  ):wait(2000)
  if result.code ~= 0 then return nil end
  return vim.trim(result.stdout or "")
end

return M
