local ls = require "luasnip"
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  s("mf", {
    t "function(",
    i(1, ""),
    t ")",
    t { "", "  " }, -- newline and indent
    i(2, "-- body"),
    t { "", " end" },
  }),
}
