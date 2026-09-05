-- ~/.config/nvim/after/ftplugin/haskell.lua
local ht = require "haskell-tools"
local keymap = require "shino.keymap"
local opts = { buffer = vim.api.nvim_get_current_buf() }
-- haskell-language-server relies heavily on codeLenses,
-- so auto-refresh (see advanced configuration) is enabled by default
keymap.nmap("<leader>cl", vim.lsp.codelens.run, "Haskell: Run code lens", opts)
-- Hoogle search for the type signature of the definition under the cursor
keymap.nmap("<leader>hs", ht.hoogle.hoogle_signature, "Haskell: Hoogle signature", opts)
-- Evaluate all code snippets
keymap.nmap("<leader>ea", ht.lsp.buf_eval_all, "Haskell: Eval all", opts)
-- Toggle a GHCi repl for the current package
keymap.nmap("<leader>rr", ht.repl.toggle, "Haskell: Toggle REPL (package)", opts)
-- Toggle a GHCi repl for the current buffer
keymap.nmap("<leader>rf", function()
  ht.repl.toggle(vim.api.nvim_buf_get_name(0))
end, "Haskell: Toggle REPL (buffer)", opts)
keymap.nmap("<leader>rq", ht.repl.quit, "Haskell: Quit REPL", opts)
