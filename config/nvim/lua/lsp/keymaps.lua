local keymap = require "shino.keymap"

local M = {}
function M.lsp_keymap(bufnr)
  local opts = { buffer = bufnr }

  -- Basics
  keymap.nmap("K", vim.lsp.buf.hover, "LSP: Hover", opts)
  keymap.nmap("<leader>gd", function()
    vim.cmd "belowright split"
    vim.lsp.buf.definition()
  end, "LSP: Go to definition (vsplit)", opts)
  keymap.nmap("gd", vim.lsp.buf.definition, "LSP: Go to definition", opts)
  keymap.nmap("gD", vim.lsp.buf.declaration, "LSP: Go to declaration", opts)
  keymap.nmap("gi", vim.lsp.buf.implementation, "LSP: Go to implementation", opts)
  keymap.nmap("gt", vim.lsp.buf.type_definition, "LSP: Go to type", opts)
  keymap.nmap("<leader>rn", vim.lsp.buf.rename, "LSP: Rename", opts)
  keymap.map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "LSP: Code action" })
  keymap.nmap("<leader>k", vim.lsp.buf.signature_help, "LSP: Signature help", opts)

  -- Diagnostics
  keymap.nmap("[d", function()
    vim.diagnostic.jump { count = -1, float = true }
  end, "Diag: Prev", opts)
  keymap.nmap("]d", function()
    vim.diagnostic.jump { count = 1, float = true }
  end, "Diag: Next", opts)
  keymap.nmap("<leader>e", vim.diagnostic.open_float, "Diag: Line info", opts)
  keymap.nmap("<leader>q", vim.diagnostic.setloclist, "Diag: To loclist", opts)

  -- Formatting (use Conform.nvim with LSP fallback)
  keymap.map({ "n", "v" }, "<leader>f", function()
    require("conform").format { async = true, lsp_format = "fallback" }
  end, { buffer = bufnr, desc = "Format with Conform" })

  -- Inlay hints toggle (NVIM ≥0.10)
  if vim.lsp.inlay_hint then
    keymap.nmap("<leader>lh", function()
      local enabled = vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }
      vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
    end, "LSP: Toggle inlay hints", opts)
  end
end

return M
