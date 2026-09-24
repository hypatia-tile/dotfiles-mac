-- Deno's built-in language server. Root detection (deno.json / deno.jsonc /
-- deno.lock) and deno: URI handlers come from nvim-lspconfig's lsp/denols.lua;
-- this file only adds the settings this config wants on top.
return {
  settings = {
    deno = {
      enable = true,
      lint = true,
      unstable = true,
    },
  },
}
