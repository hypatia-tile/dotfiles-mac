-- ~/.config/nvim/after/ftplugin/lua.lua
-- Consolidated Lua ftplugin settings (runs after built-in/plugin ftplugins)

if vim.b.did_my_lua_ftplugin then
  return
end
vim.b.did_my_lua_ftplugin = true

-- Indentation settings
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2

-- Line width for Lua files
vim.opt_local.textwidth = 100

-- Cleanup on filetype change
vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "") .. " | setlocal shiftwidth< tabstop< textwidth<"
