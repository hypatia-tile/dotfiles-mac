-- Windows that only make sense next to a Lean buffer: the infoview, and the
-- stderr window lean.nvim hangs off it.
local AUXILIARY_FILETYPES = {
  leaninfo = true,
  leanstderr = true,
}

---Tear down a tab's leftover Lean windows once nothing is left for them to track.
---
---When the last window holding a real buffer in the tab goes away, the
---infoview has nothing to report on, so it goes too. If those leftovers were
---the last windows standing, quitting is what `:q` would have done had the
---infoview never been there.
---@param tabpage integer
local function close_orphaned_lean_windows(tabpage)
  if not vim.api.nvim_tabpage_is_valid(tabpage) then
    return
  end

  local windows = vim.api.nvim_tabpage_list_wins(tabpage)
  for _, window in ipairs(windows) do
    if not AUXILIARY_FILETYPES[vim.bo[vim.api.nvim_win_get_buf(window)].filetype] then
      return
    end
  end

  -- nvim_win_close refuses to close the very last window (E444), so once this
  -- is the only tab left there is nothing to fall back on but quitting.
  if #vim.api.nvim_list_tabpages() == 1 then
    vim.cmd "confirm quitall"
    return
  end
  for _, window in ipairs(windows) do
    vim.api.nvim_win_close(window, true)
  end
end

return {
  "Julian/lean.nvim",
  event = { "BufReadPre *.lean", "BufNewFile *.lean" },

  dependencies = {
    -- optional dependencies:

    -- a completion engine
    --    hrsh7th/nvim-cmp or Saghen/blink.cmp are popular choices

    -- 'nvim-telescope/telescope.nvim', -- for Lean-specific pickers
    -- 'andymass/vim-matchup',          -- for enhanced % motion behavior
    -- 'andrewradev/switch.vim',        -- for switch support
    -- 'tomtom/tcomment_vim',           -- for commenting
  },

  config = function()
    vim.g.lean_config = {
      mappings = true,
    }

    local au = require "shino.autocmd"
    au.autocmd("WinClosed", "Close the Lean infoview once nothing is left for it to track", {
      group = au.group "shino_lean_infoview",
      callback = function(args)
        -- WinClosed fires while the window is still around, so look at the tab
        -- again once it is actually gone.
        local window = tonumber(args.match)
        if not window or not vim.api.nvim_win_is_valid(window) then
          return
        end
        local tabpage = vim.api.nvim_win_get_tabpage(window)
        vim.schedule(function()
          close_orphaned_lean_windows(tabpage)
        end)
      end,
    })
  end,
}
