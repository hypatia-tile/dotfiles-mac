---@meta luasnip

-- LuaSnip declares its module's class, `LuaSnip`, on an assignment to a local
-- declared earlier without a type, and LuaLS does not carry that class to
-- `require "luasnip"`. Every field then reads as undefined: the lazily loaded
-- node constructors and the API functions alike. This names the class the
-- plugin already defines, so nothing here lists fields that could go stale.

---@type LuaSnip
local M
return M
