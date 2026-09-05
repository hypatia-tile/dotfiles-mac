# 0001. Provision OCaml LSP tooling via opam, wired through the native LSP API

- Date: 2026-08-04
- Status: Accepted

## Context

The config is gaining OCaml support, primarily to learn the language, so
the priority is a beginner-friendly editor experience rather than a
power-user setup. The relevant facts:

- OCaml's language server is `ocaml-lsp-server` (the `ocamllsp` binary);
  it is the only mature option.
- `ocaml-lsp-server` runs inside an opam switch and must match the
  project's compiler. Formatting (`ocamlformat`) and the REPL (`utop`)
  are likewise opam packages, and `ocamlformat` only runs when a
  `.ocamlformat` file exists at the project root.
- This config already sources most language servers from the environment
  and PATH (`nil`, `clangd`), reserving mason only for `gh_actions_ls`.
  Servers are wired with the Neovim 0.11+ native API: a per-server table
  in `after/lsp/<server>.lua` plus `vim.lsp.enable` from
  `after/ftplugin/<ft>.lua`.
- mason can install `ocaml-lsp-server`, but the mason build is not tied
  to the project's opam switch and frequently fails to match the
  compiler — a common, hard-to-debug beginner trap.

## Decision

Provision the OCaml toolchain (`ocaml-lsp-server`, `ocamlformat`, and
later `utop`) via opam, and reference `ocamllsp` on PATH from the native
LSP config (`after/lsp/ocamllsp.lua` + `after/ftplugin/ocaml.lua`), the
same shape used for `nil` and `clangd`. mason was rejected because its
server build is switch-agnostic and breaks against real projects; a
Nix-provided server (dotfiles-mac) was rejected because it fits the
system poorly with OCaml's per-project switches.

Beginner-friendly defaults are enabled in the server config: inlay hints
for let bindings and pattern variables (shown automatically on attach,
while other filetypes keep the global off default), `extendedHover`, and
`syntaxDocumentation`. `codelens` is left off as it duplicates the inlay
hints. Formatting goes through Conform (`ocaml = { "ocamlformat" }`) on
the existing format-on-save path, which no-ops without a `.ocamlformat`.

## Consequences

- Adding OCaml requires an out-of-repo step: `opam install
  ocaml-lsp-server ocamlformat dune` in the active switch. This is
  unavoidable — OCaml tooling is switch-scoped — and teaches the opam
  workflow a beginner needs anyway.
- The editor side stays consistent with the rest of the config (native
  API, PATH-provided server) and carries no mason entry for OCaml.
- A REPL (`utop`) integration and dune-file LSP attachment are
  deferred; both are easy follow-ups once the core setup is in use.
- This is the first ADR, establishing the record for tool-adoption and
  provisioning-policy decisions going forward.
