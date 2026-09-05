local au = require "shino.autocmd"

au.autocmd("BufEnter", "Drop auto-comment continuation (c/r/o) from formatoptions", {
  callback = function()
    vim.opt.formatoptions = vim.opt.formatoptions - { "c", "r", "o" }
  end,
})
