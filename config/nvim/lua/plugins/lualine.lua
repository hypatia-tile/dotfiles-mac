return {
  "nvim-lualine/lualine.nvim",
  -- File icons come from mini.icons via its nvim-web-devicons mock
  -- (lua/plugins/mini-icons.lua).
  dependencies = { "nvim-mini/mini.icons" },
  opts = {
    options = {
      theme = "dracula",
    },
  },
}
