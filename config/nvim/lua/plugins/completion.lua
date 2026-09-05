return {
  {
    "saghen/blink.cmp",
    version = "*", -- keep current stable
    lazy = false, -- completion should be ready in InsertEnter
    dependencies = {
      -- Snippets are optional. If you already use LuaSnip/friendly-snippets, keep them.
      "L3MON4D3/LuaSnip",
      "rafamadriz/friendly-snippets",
    },
    opts = {
      -- Basic sane defaults
      keymap = {
        preset = "default",
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
      },
      sources = {
        default = { "lazydev", "lsp", "path", "buffer", "snippets" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
        },
      },
      signature = { enabled = true }, -- show function signatures as you type
      -- If you use LuaSnip:
      snippets = { preset = "luasnip" },
    },
  },
}
