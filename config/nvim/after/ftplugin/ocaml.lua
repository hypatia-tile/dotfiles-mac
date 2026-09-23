local keymap = require "shino.keymap"
local opts = { buffer = vim.api.nvim_get_current_buf() }

vim.lsp.enable "ocamllsp"

-- Toggle a utop REPL in a split, mirroring haskell-tools' <leader>rr UX (#71).
-- utop must be on PATH (`opam install utop`); no OCaml nvim plugin provides this.
local function toggle_utop()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.b[buf].ocaml_utop then
      vim.api.nvim_win_close(win, true)
      return
    end
  end
  vim.cmd "split"
  vim.cmd "terminal utop"
  vim.b.ocaml_utop = true
  vim.cmd "startinsert"
end

keymap.nmap("<leader>rr", toggle_utop, "OCaml: Toggle utop REPL", opts)
