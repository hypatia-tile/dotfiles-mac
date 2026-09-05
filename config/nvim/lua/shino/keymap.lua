-- Typed, semantic wrappers around vim.keymap.set.
--
-- `map` is the thin escape hatch for multi-mode or unusual mappings; the
-- per-mode helpers (`nmap`, `imap`, `vmap`, `xmap`) make `desc` a required
-- positional argument so every semantic mapping is self-documenting. The
-- `opts` type is borrowed from Neovim's own `vim.keymap.set.Opts`, so
-- completion and diagnostics on the fields (buffer, silent, ...) survive the
-- abstraction. Buffer-local mappings are expressed via `opts.buffer`.

local M = {}

---Set a key mapping. Defaults `silent = true` unless overridden.
---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param opts? vim.keymap.set.Opts
function M.map(mode, lhs, rhs, opts)
  opts = vim.tbl_extend("keep", opts or {}, { silent = true })
  vim.keymap.set(mode, lhs, rhs, opts)
end

---Normal-mode mapping. `desc` is required.
---@param lhs string
---@param rhs string|function
---@param desc string
---@param opts? vim.keymap.set.Opts
function M.nmap(lhs, rhs, desc, opts)
  M.map("n", lhs, rhs, vim.tbl_extend("force", opts or {}, { desc = desc }))
end

---Insert-mode mapping. `desc` is required.
---@param lhs string
---@param rhs string|function
---@param desc string
---@param opts? vim.keymap.set.Opts
function M.imap(lhs, rhs, desc, opts)
  M.map("i", lhs, rhs, vim.tbl_extend("force", opts or {}, { desc = desc }))
end

---Visual-mode mapping. `desc` is required.
---@param lhs string
---@param rhs string|function
---@param desc string
---@param opts? vim.keymap.set.Opts
function M.vmap(lhs, rhs, desc, opts)
  M.map("v", lhs, rhs, vim.tbl_extend("force", opts or {}, { desc = desc }))
end

---Visual-block (x) mode mapping. `desc` is required.
---@param lhs string
---@param rhs string|function
---@param desc string
---@param opts? vim.keymap.set.Opts
function M.xmap(lhs, rhs, desc, opts)
  M.map("x", lhs, rhs, vim.tbl_extend("force", opts or {}, { desc = desc }))
end

return M
