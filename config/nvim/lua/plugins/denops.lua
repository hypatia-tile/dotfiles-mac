return {
  "vim-denops/denops.vim",
  lazy = false, -- Load on startup
  priority = 500,
  config = function()
    -- Enable denops debug logging
    vim.g["denops#debug"] = 1
  end,
}
