return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-ui-select.nvim",
    "luc-tielen/telescope_hoogle",
  },
  event = "VeryLazy",
  config = function()
    local telescope = require "telescope"
    telescope.setup {
      defaults = {
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
          "--hidden",
          "--glob=!.git/**",
        },
        file_ignore_patterns = { "^%.git/" },
      },
      pickers = {
        find_files = {
          hidden = true,
        },
      },
      extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown {},
        },
      },
    }
    telescope.load_extension "ui-select"
    telescope.load_extension "hoogle"

    local builtin = require "telescope.builtin"
    local keymap = require "shino.keymap"
    keymap.nmap("<C-p>", builtin.find_files, "Telescope: Find files")
    keymap.nmap("sg", builtin.live_grep, "Telescope: Live grep")
    keymap.nmap("gr", builtin.lsp_references, "Telescope: LSP references")
    keymap.nmap("<leader>ss", builtin.lsp_document_symbols, "Telescope LSP Doc symbols")
    keymap.nmap("<leader>sS", builtin.lsp_workspace_symbols, "Telescope LSP WS symbols")
  end,
}
