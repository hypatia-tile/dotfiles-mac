-- ocaml-lsp-server, provided on PATH via opam (see docs/adr/0001).
-- Beginner-friendly defaults: inlay hints for let bindings and pattern
-- variables (shown automatically, see on_attach), a richer hover, and
-- syntax documentation in hover.
return {
  cmd = { "ocamllsp" },
  filetypes = { "ocaml" },
  root_markers = { "dune-project", "dune-workspace", ".git" },
  settings = {
    extendedHover = { enable = true },
    syntaxDocumentation = { enable = true },
    inlayHints = {
      hintPatternVariables = true,
      hintLetBindings = true,
    },
  },
  on_attach = function(_, bufnr)
    -- Show inferred types inline while learning OCaml. Other filetypes keep
    -- the global default (off, toggle with <leader>lh).
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end,
}
