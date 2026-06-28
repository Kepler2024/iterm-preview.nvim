if vim.g.loaded_iterm_preview then return end
vim.g.loaded_iterm_preview = 1

vim.api.nvim_create_user_command(
  "ItermMdPreview",
  function() require("iterm-preview").preview() end,
  { desc = "Open markdown preview in an iTerm browser split" }
)

vim.api.nvim_create_user_command(
  "ItermMdPreviewStop",
  function() require("iterm-preview").stop() end,
  { desc = "Close the iTerm preview split and stop the preview server" }
)
