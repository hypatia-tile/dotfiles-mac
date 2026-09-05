-- Single icon provider for the whole config. mini.icons masquerades as
-- nvim-web-devicons so plugins that hardcode that dependency (lualine,
-- telescope, ...) transparently use mini.icons.
return {
  "nvim-mini/mini.icons",
  lazy = true,
  opts = {},
  config = function(_, opts)
    require("mini.icons").setup(opts)
    MiniIcons.mock_nvim_web_devicons()
  end,
  init = function()
    -- Load mini.icons (and mock) on demand the first time any plugin
    -- requires "nvim-web-devicons". Order-independent, per mini.icons docs.
    package.preload["nvim-web-devicons"] = function()
      require("mini.icons").mock_nvim_web_devicons()
      return package.loaded["nvim-web-devicons"]
    end
  end,
}
