vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.hlsearch = true
vim.opt.clipboard:append "unnamedplus,unnamed"
vim.opt.wrap = false
vim.g.tex_flavor = "latex" -- Open .tex files in LaTeX mode

vim.opt.termguicolors = true
vim.opt.winblend = 0 -- transparency for window
vim.opt.pumblend = 0 -- transparency for popup menu

-- emphasize cursorline
vim.opt.cursorline = true
require("shino.highlight").set("CursorLineNr", { fg = "#ff9e64", bold = true })

vim.opt.splitright = true
vim.opt.splitbelow = true

-- Folding via Treesitter, all folds open on open
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldtext = ""
vim.opt.foldlevel = 99

vim.filetype.add {
  pattern = {
    ["compose.*%.ya?ml"] = "yaml.docker-compose",
    ["docker%-compose.*%.ya?ml"] = "yaml.docker-compose",
    [".*/%.github/workflows/.*%.ya?ml"] = "yaml.github-actions",
    ["%.env.*"] = "sh.env",
  },
}
