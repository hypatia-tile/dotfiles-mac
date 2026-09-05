-- Typed wrappers around vim.api.nvim_set_hl (global namespace).
--
-- `set` drops the `0` namespace boilerplate; `extend` folds the common
-- get_hl + merge pattern (define a group by inheriting from an existing one).
-- `val` borrows Neovim's own `vim.api.keyset.highlight` type, so completion
-- and diagnostics on the fields (fg, bg, bold, link, ...) survive.

local M = {}

---Define a highlight group in the global namespace.
---@param name string
---@param val vim.api.keyset.highlight
function M.set(name, val)
  vim.api.nvim_set_hl(0, name, val)
end

---Define a highlight group by extending an existing one. `val` is merged
---over the resolved attributes of `base`.
---@param name string
---@param base string
---@param val vim.api.keyset.highlight
function M.extend(name, base, val)
  M.set(name, vim.tbl_extend("force", vim.api.nvim_get_hl(0, { name = base }), val))
end

return M
