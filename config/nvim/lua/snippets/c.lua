local ls = require "luasnip"
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local sn = ls.snippet_node

return {
  s("headerdef", {
    t "#ifndef ",
    d(1, function()
      local fn = vim.fn.expand "%:t:r"
      local guard = fn ~= "" and (fn:upper():gsub("[^A-Z0-9]", "_") .. "_H") or "HEADER_H"
      return sn(nil, { i(1, guard) })
    end),
    t { "", "#define " },
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t { "", "", "" },
    i(2),
    t { "", "#endif // " },
    f(function(args)
      return args[1][1]
    end, { 1 }),
  }),
}
