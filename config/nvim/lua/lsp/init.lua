local au = require "shino.autocmd"

-- Global LspAttach autocmd to attach keymaps to all LSP clients
au.autocmd("LspAttach", "Attach global LSP keymaps on every client attach", {
  callback = function(args)
    require("lsp.keymaps").lsp_keymap(args.buf)
  end,
})

local ts_filetypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "typescript.tsx",
  "json",
}
vim.lsp.config("denols", {
  filetypes = ts_filetypes,
  init_options = {
    enable = true,
    lint = true,
    unstable = true,
    suggest = {
      imports = {
        hosts = {
          ["https://deno.land"] = true,
        },
      },
    },
  },
})
au.autocmd("FileType", "Start denols for TypeScript/JavaScript buffers", {
  pattern = ts_filetypes,
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local root_dir = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" }) or vim.fn.expand "%:h"
    vim.lsp.start {
      name = "denols",
      root_dir = root_dir,
      bufnr = bufnr,
      cmd = { "deno", "lsp" },
    }
  end,
})

vim.lsp.enable "copilot"
