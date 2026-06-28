local M = {}

local function ensure_vim_func()
  vim.cmd([[
    function! ItermMdpreviewBrowserFunc(url) abort
      call v:lua.require'iterm-preview'.open_url(a:url)
    endfunction
  ]])
end

function M.install(opts)
  ensure_vim_func()
  if vim.g.mkdp_port == nil then vim.g.mkdp_port = opts.port end
  if vim.g.mkdp_filetypes == nil then vim.g.mkdp_filetypes = opts.filetypes end
  vim.g.mkdp_browserfunc = "ItermMdpreviewBrowserFunc"
  vim.g.mkdp_auto_close = 1
end

return M
