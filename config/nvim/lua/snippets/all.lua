local ls = require "luasnip"
local s = ls.snippet
local t = ls.text_node

return {
  s("date", {
    t(os.date "%Y-%m-%d"),
  }),
}
