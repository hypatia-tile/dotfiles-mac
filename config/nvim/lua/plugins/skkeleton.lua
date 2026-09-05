-- skkeleton {{{
return {
  "vim-skk/skkeleton",
  dependencies = { "vim-denops/denops.vim" },
  lazy = false, -- Load on startup so denops can discover it
  keys = {
    { "<C-j>", "<Plug>(skkeleton-toggle)", desc = "Toggle skkeleton", mode = "i" },
  },
  config = function()
    -- The config dir is a read-only Nix store path (placed by dotfiles-mac),
    -- so both dictionaries live outside it: the L dictionary is provided by
    -- Home Manager at ~/.local/share/skk, and the user dictionary needs a
    -- writable location in nvim's data dir.
    vim.fn["skkeleton#config"] {
      globalDictionaries = {
        vim.fn.expand "~/.local/share/skk/SKK-JISYO.L",
      },
      userDictionary = vim.fn.stdpath "data" .. "/skk/user-dict",
      eggLikeNewline = true,
    }
  end,
}
-- }}}
