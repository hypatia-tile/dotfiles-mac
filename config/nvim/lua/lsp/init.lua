local au = require "shino.autocmd"

-- Global LspAttach autocmd to attach keymaps to all LSP clients
au.autocmd("LspAttach", "Attach global LSP keymaps on every client attach", {
  callback = function(args)
    require("lsp.keymaps").lsp_keymap(args.buf)
  end,
})

-- denols: config in after/lsp/denols.lua + nvim-lspconfig; attaches only when
-- the buffer sits under a Deno project root (see nvim-lspconfig's root_dir).
vim.lsp.enable "denols"
vim.lsp.enable "copilot"
