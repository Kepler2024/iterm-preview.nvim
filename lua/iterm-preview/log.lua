local M = {}

local PREFIX = "[iterm-preview] "
local level = vim.log.levels.INFO

function M.set_level(lvl)
  if type(lvl) == "number" then level = lvl end
end

local function emit(msg, lvl)
  if lvl < level then return end
  vim.schedule(function() vim.notify(PREFIX .. msg, lvl) end)
end

function M.debug(msg) emit(msg, vim.log.levels.DEBUG) end
function M.info(msg) emit(msg, vim.log.levels.INFO) end
function M.warn(msg) emit(msg, vim.log.levels.WARN) end
function M.error(msg) emit(msg, vim.log.levels.ERROR) end

return M
