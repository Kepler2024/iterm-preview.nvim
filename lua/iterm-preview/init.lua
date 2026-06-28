local M = {}

local config = require("iterm-preview.config")
local mkdp = require("iterm-preview.mkdp")
local iterm = require("iterm-preview.iterm")
local state = require("iterm-preview.state")
local log = require("iterm-preview.log")

M._opts = nil

local function override_for_buffer(buf)
  if not vim.api.nvim_buf_is_loaded(buf) then return end
  if vim.bo[buf].filetype ~= "markdown" then return end
  pcall(vim.api.nvim_buf_create_user_command, buf, "MarkdownPreviewStop", function()
    log.debug("override :MarkdownPreviewStop fired (buffer-local)")
    M.stop()
  end, { force = true, desc = "Stop preview (overridden by iterm-preview)" })
end

local function install_stop_override()
  -- Global fallback in case the command is invoked from a non-markdown buffer.
  vim.api.nvim_create_user_command("MarkdownPreviewStop", function()
    log.debug("override :MarkdownPreviewStop fired (global)")
    M.stop()
  end, { force = true, desc = "Stop preview (overridden by iterm-preview)" })
  -- mkdp installs a buffer-local :MarkdownPreviewStop on every markdown buffer
  -- (which takes precedence over global commands). Override every currently
  -- loaded markdown buffer; the FileType autocmd handles future ones.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    override_for_buffer(buf)
  end
end

local function register_autocmds(opts)
  local group = vim.api.nvim_create_augroup("ItermMdpreview", { clear = true })

  -- Keep our buffer-local :MarkdownPreviewStop override winning over mkdp's,
  -- which is itself installed via FileType=markdown. vim.schedule defers to
  -- the next tick so we run *after* mkdp's autocmd in the same event chain.
  vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
    group = group,
    pattern = "markdown",
    callback = function(args)
      vim.schedule(function() override_for_buffer(args.buf) end)
    end,
  })

  if not opts.auto_close then return end
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    group = group,
    callback = function(args)
      -- Only tear down when the *previewed* buffer goes away. Matching on bufnr
      -- (not just filetype) avoids killing the preview when an unrelated
      -- markdown buffer is closed. BufWipeout/BufDelete (not BufUnload) also
      -- spares the preview from `:edit` reloads of the same buffer.
      if not state.has_session() then return end
      if args.buf ~= state.bufnr then return end
      M.stop()
    end,
  })
end

function M.setup(user_opts)
  if vim.fn.has("mac") ~= 1 then
    log.warn("iterm-preview only supports macOS; setup skipped")
    return
  end

  local ok, opts = pcall(config.merge, user_opts)
  if not ok then
    log.error("invalid config: " .. tostring(opts))
    return
  end

  M._opts = opts
  log.set_level(opts.notify_level)
  mkdp.install(opts)
  register_autocmds(opts)
end

local function is_supported_ft(ft)
  local fts = (M._opts and M._opts.filetypes) or { "markdown" }
  for _, f in ipairs(fts) do
    if f == ft then return true end
  end
  return false
end

function M.preview()
  if not M._opts then
    log.error("setup() not called; add require('iterm-preview').setup() to your config")
    return
  end
  if not is_supported_ft(vim.bo.filetype) then
    log.error(
      "not a preview-able buffer (filetype '" .. vim.bo.filetype .. "'); open a markdown file first"
    )
    return
  end
  if vim.fn.exists(":MarkdownPreview") ~= 2 then
    log.error("iamcco/markdown-preview.nvim not installed (or not loaded for this buffer)")
    return
  end
  vim.cmd("MarkdownPreview")
end

function M.stop()
  if not M._opts then return end
  log.debug(
    string.format(
      "stop: has_session=%s session_id=%s",
      tostring(state.has_session()),
      tostring(state.session_id)
    )
  )
  if state.has_session() then
    iterm.close_split(state.session_id, M._opts)
    state.clear()
  end
  -- Call mkdp's underlying stop function directly to avoid recursing into our
  -- own :MarkdownPreviewStop override.
  pcall(vim.fn["mkdp#util#stop_preview"])
end

function M.open_url(url)
  if not M._opts then return end
  -- Single-preview model: at most one pane at a time. Always close an existing
  -- pane before opening a new one so re-previewing (e.g. on a second markdown
  -- file) never orphans a split the plugin can no longer track or close.
  if state.has_session() then
    iterm.close_split(state.session_id, M._opts)
    state.clear()
  end
  local buf = vim.api.nvim_get_current_buf()
  local session_id = iterm.open_split(url, M._opts)
  if session_id and session_id ~= "" then
    state.set(session_id, url, buf)
    log.debug("preview opened (session " .. session_id .. "); override installed")
    install_stop_override()
    -- mkdp may have just installed its buffer-local command on this buffer;
    -- schedule a re-override after the current event chain settles.
    vim.schedule(function() override_for_buffer(buf) end)
  else
    log.error("failed to open iTerm preview split; run :checkhealth iterm-preview")
  end
end

function M.get_opts() return M._opts end

return M
