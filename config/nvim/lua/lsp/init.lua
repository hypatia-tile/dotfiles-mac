local au = require "shino.autocmd"

-- Global LspAttach autocmd to attach keymaps to all LSP clients
au.autocmd("LspAttach", "Attach global LSP keymaps on every client attach", {
  callback = function(args)
    require("lsp.keymaps").lsp_keymap(args.buf)
  end,
})

-- denols: config in after/lsp/denols.lua (+ nvim-lspconfig handlers).
-- Attaches under a Deno project, or for a lone JS/TS file with no package.json.
vim.lsp.enable "denols"
vim.lsp.enable "copilot"
