-- lua/plugins/lsp-config.lua
return {
  {
    "mason-org/mason.nvim",
    optional = true,
    config = function()
      require("mason").setup {
        ui = {
          border = "rounded",
        },
      }
    end,
  },
  {
    "mason-org/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup {
        ensure_installed = {
          "gh_actions_ls",
        },
        automatic_installation = {
          exclude = {
            "denols",
          },
        },
      }
    end,
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      -- NOTE: nvim-lspconfig is a dependency of mason-lspconfig but not directly used.
      -- This config uses Neovim 0.11+ native LSP API (vim.lsp.config/enable) instead.
      "neovim/nvim-lspconfig",
    },
  },
}
