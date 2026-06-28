-- Minimal init for running tests with plenary's busted runner.
-- Usage:
--   nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/"

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.runtimepath:prepend(root)

local plenary = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
if vim.fn.isdirectory(plenary) == 1 then vim.opt.runtimepath:prepend(plenary) end

vim.cmd("runtime plugin/plenary.vim")
