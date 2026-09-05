-- Bootstrap. Keep this thin: options, keymaps, autocmds, plugins, then LSP.
require "vim-options" -- global options and mapleader (<Space>)
require "keymaps" -- global, non-plugin keymaps
require "autocmds" -- global autocmds
require "config.lazy" -- lazy.nvim bootstrap, loads lua/plugins/*
require "shino.commands" -- user commands (:InitLua)
require "lsp.init" -- global LspAttach handler and denols startup
