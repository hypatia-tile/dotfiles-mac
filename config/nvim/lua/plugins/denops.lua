return {
  "vim-denops/denops.vim",
  lazy = false, -- Load on startup
  priority = 500,
  config = function()
    -- Enable denops debug logging — except in a firenvim instance. firenvim
    -- collects whatever Neovim prints while starting and hands it to the
    -- browser as `messages` instead of letting the frame come up, so debug
    -- output is not a log there, it is interference.
    vim.g["denops#debug"] = vim.g.started_by_firenvim and 0 or 1
  end,
}
