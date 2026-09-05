-- Typed, semantic wrappers around vim.api.nvim_create_autocmd/augroup.
--
-- `autocmd` makes `desc` a required positional argument so every autocommand
-- is self-documenting, mirroring shino.keymap. `opts` borrows Neovim's own
-- `vim.api.keyset.create_autocmd` type, so completion and diagnostics on the
-- fields (callback, pattern, group, ...) survive the abstraction. `group` is
-- a shorthand for a cleared augroup.

local M = {}

---Create an autocommand group, cleared by default.
---@param name string
---@return integer
function M.group(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

---Create an autocommand. `desc` is required.
---@param event string|string[]
---@param desc string
---@param opts vim.api.keyset.create_autocmd
---@return integer
function M.autocmd(event, desc, opts)
  return vim.api.nvim_create_autocmd(event, vim.tbl_extend("force", opts, { desc = desc }))
end

return M
