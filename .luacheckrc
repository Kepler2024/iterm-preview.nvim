std = "lua51+luajit"
globals = { "vim" }
ignore = {
  "212", -- unused argument
  "631", -- line too long
}
exclude_files = { ".luarocks", ".tests" }
