-- Deno's built-in language server. deno: URI handlers still come from
-- nvim-lspconfig's lsp/denols.lua; root_dir is overridden here so a lone
-- .ts/.js file (no deno.json) still gets a working client. The previous
-- "fall back to expand('%:h')" path could disagree with the buffer URI on
-- macOS (/var vs /private/var) and left an attached client with empty
-- hover and diagnostics.
--
-- Confirmed: root = vim.fs.dirname(nvim_buf_get_name(bufnr)) with matching
-- /private paths yields diagnostics without a deno.json; nvim-lspconfig's
-- stricter root_dir refuses to attach in that case.
local function root_dir(bufnr, on_dir)
  local deno_root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" })
  if deno_root then
    return on_dir(deno_root)
  end
  -- Node-style trees are not Deno; leave them alone (this config has no ts_ls).
  if vim.fs.root(bufnr, { "package.json" }) then
    return
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name ~= "" then
    on_dir(vim.fs.dirname(name))
  end
end

return {
  root_dir = root_dir,
  settings = {
    deno = {
      enable = true,
      lint = true,
      unstable = true,
    },
  },
}
