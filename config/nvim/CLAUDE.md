# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Neovim configuration based on [lazy.nvim](https://github.com/folke/lazy.nvim) (not LazyVim — `lazyvim.json` enables a few LazyVim extras but the core setup is custom). The config targets Neovim 0.11+ and uses the native LSP API (`vim.lsp.config`/`vim.lsp.enable`) rather than nvim-lspconfig's setup helpers.

## Decision records

- Decisions about this config that are not obvious from the code are
  written up as ADRs in `docs/adr/` (English, one file per decision,
  `NNNN-kebab-case-title.md`, based on `docs/adr/template.md`). See
  `docs/adr/README.md`.
- ADRs are documentation, not a gate: they record decisions but do not
  block changes. Reserve them for decision-class changes (policy,
  structure, tool adoption); day-to-day configuration edits need none.

## Language policy

- Conversation with the owner and review output may be in Japanese;
  identifiers, function names, and technical terms stay in English.
- All documents, code comments, commit messages, and ADRs are in English.

## Commit conventions

- Conventional Commits, in English: `type(scope): subject`.

## Trying the config from this repo

`~/.config/nvim` is a read-only Nix store copy of this repo, placed by
[dotfiles-mac](https://github.com/hypatia-tile/dotfiles-mac) as a pinned
non-flake input. Edits here take effect in the real environment only after
pushing and bumping the pin. To verify the working tree directly:

- `bin/nvim-dev` — launch Neovim on this working tree via
  `NVIM_APPNAME=nvim-dev` (maintains a `~/.config/nvim-dev` symlink to this
  repo; data/state/cache are isolated from the real environment, so the
  first launch installs all plugins).
- `bin/check` — headless load check: full startup including a
  `lazy-lock.json`-faithful plugin restore, sharing the `nvim-dev` data dir.
  Reports errors verbatim and exits non-zero on failure.

## Formatting

Lua files are formatted with **stylua**. Settings are in `.stylua.toml`:
- 2-space indent, 120-column width, double-quote preference, no parentheses on calls

Run manually:
```bash
stylua lua/ after/ ftplugin/ init.lua
```

Format-on-save via Conform is enabled for Lua (stylua), Nix (nixfmt), and OCaml (ocamlformat, only when a `.ocamlformat` file exists at the project root), and disabled for Haskell (fourmolu must be run manually with `<leader>f`).

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs on pull requests and on
pushes to `main`. Two required checks:
- **stylua**: `stylua --check` on `lua/ after/ ftplugin/ init.lua`.
- **check**: `bin/check` — headless startup with a `lazy-lock.json`-faithful
  plugin restore. Installs Neovim and Deno (needed by denops/skkeleton) and
  caches the `nvim-dev` plugin dir across runs.

## Debugging

Use `nvim --startuptime /tmp/startup.log` to profile startup time.

## Architecture

### Entry Point

`init.lua` is a thin bootstrap — an ordered list of requires, nothing else:
1. `vim-options` — global options (incl. folding) and mapleader (`<Space>`)
2. `keymaps` — global, non-plugin keymaps (buffer nav, window resize, insert arrows)
3. `autocmds` — global autocmds
4. `config.lazy` — lazy.nvim bootstrap, loads all `lua/plugins/*.lua`
5. `shino.commands` — user commands (`:InitLua`)
6. `lsp.init` — global `LspAttach` handler and denols startup for TypeScript filetypes

### Plugin Structure

All plugins live in `lua/plugins/*.lua` — each file returns a lazy.nvim plugin spec. There is no plugin registry file; lazy.nvim scans the directory automatically.

### LSP Setup

LSP uses the Neovim 0.11+ native API instead of lspconfig setup calls:
- **Global keymaps**: `lua/lsp/keymaps.lua` — attached on every `LspAttach` event
- **TypeScript (Deno only)**: `lua/lsp/init.lua` sets static `denols` options via `vim.lsp.config`, then a `FileType` autocmd calls `vim.lsp.start` per buffer, rooting at `deno.json`/`deno.jsonc` (falling back to the file's directory). Only Deno is supported; there is no `ts_ls`/tsserver path.
- **Per-server configs**: `after/lsp/<server>.lua` — lua_ls, nil_ls, copilot, gh_actions_ls, ocamllsp
- **OCaml**: `ocamllsp` (opam-provided, see `docs/adr/0001`) with beginner-friendly defaults — inlay hints auto-enabled on attach, `extendedHover`, `syntaxDocumentation`. Enabled from `after/ftplugin/ocaml.lua`.
- **Language-specific plugins** bypass the global attach: haskell-tools.nvim (Haskell), lean.nvim (Lean), nvim-jdtls (Java)

### Completion

**blink.cmp** replaces nvim-cmp. Sources (in priority order): lazydev → lsp → path → buffer → snippets. Snippets use LuaSnip with custom snippet files in `lua/snippets/`.

### LuaSnip Keymaps

| Key | Action |
|-----|--------|
| `<C-K><C-K>` | Expand snippet |
| `<C-K><C-L>` | Jump forward |
| `<C-K><C-J>` | Jump backward |
| `<C-K><C-E>` | Cycle choice node |

### File-Type Specific Setup

`after/ftplugin/<ft>.lua` files run after built-in ftplugins:
- **haskell**: GHCi REPL toggle (`<leader>rr`/`<leader>rf`), Hoogle search (`<leader>hs`), eval all (`<leader>ea`)
- **rust**: rustaceanvim code actions (`<leader>a`) and hover actions (`K`)
- **zig**: enables `zls` LSP
- **java**: enables `jdtls` LSP
- **ocaml**: enables `ocamllsp` LSP

`ftplugin/` (non-after) also has `java.lua` and `markdown.lua`.

### Japanese Input

**skkeleton** + **denops.vim** provides SKK Japanese input. Toggle with `<C-j>` in insert mode. Dictionary at `~/.local/share/skk/SKK-JISYO.L` (placed by dotfiles-mac via Home Manager), user dict at `stdpath("data")/skk/user-dict` — both outside the config dir, which is a read-only Nix store path.

### Key Global Keymaps

| Key | Mode | Action |
|-----|------|--------|
| `H` / `L` | n | Previous/next buffer |
| `<C-p>` | n | Telescope find files |
| `sg` | n | Telescope live grep |
| `gr` | n | Telescope LSP references |
| `<C-h/j/k/l>` | n | Tmux/Neovim pane navigation |
| `<leader>tp` | n | Toggle transparent background |
| `<leader>tc` | n | Toggle Copilot suggestions |
| Arrow keys | n | Resize windows |
| Arrow keys | i | Insert Unicode arrows (←↑→↓) |

LSP mappings are buffer-local, attached on every `LspAttach`
(`lua/lsp/keymaps.lua`):

| Key | Mode | Action |
|-----|------|--------|
| `K` | n | Hover |
| `gd` / `gD` | n | Go to definition / declaration |
| `gi` / `gt` | n | Go to implementation / type |
| `<leader>gd` | n | Go to definition (below split) |
| `<leader>k` | n | Signature help |
| `<leader>rn` | n | Rename |
| `<leader>ca` | n/v | Code action |
| `<leader>f` | n/v | Format (Conform + LSP fallback) |
| `<leader>lh` | n | Toggle inlay hints |
| `<leader>ss` / `<leader>sS` | n | Telescope document / workspace symbols |
| `[d` / `]d` | n | Previous / next diagnostic |
| `<leader>e` | n | Diagnostic line info (float) |
| `<leader>q` | n | Diagnostics to loclist |

### Custom Modules (`lua/shino/`)

- `commands.lua` — `:InitLua` (open init.lua in editor)
- `keymap.lua` — typed wrappers over `vim.keymap.set`. Prefer these over
  `vim.keymap.set` directly:
  - `map(mode, lhs, rhs, opts?)` — thin escape hatch for multi-mode or
    unusual mappings; `desc` optional. Defaults `silent = true`.
  - `nmap`/`imap`/`vmap`/`xmap(lhs, rhs, desc, opts?)` — per-mode helpers
    with `desc` **required** (every semantic mapping is self-documenting).
    Buffer-local mappings pass `{ buffer = bufnr }` via `opts`.
  - `opts` borrows Neovim's `vim.keymap.set.Opts` type, so field completion
    survives. Do not add dynamic dispatch (`__index`); it defeats LuaLS.
- `autocmd.lua` — typed wrappers over `nvim_create_autocmd`/`augroup`. Prefer
  these over the raw API:
  - `autocmd(event, desc, opts)` — `desc` **required** (self-documenting);
    `opts` borrows `vim.api.keyset.create_autocmd`.
  - `group(name)` — cleared-augroup shorthand.
- `highlight.lua` — typed wrappers over `nvim_set_hl` (global namespace):
  - `set(name, val)` — drops the `0` namespace; `val` borrows
    `vim.api.keyset.highlight`.
  - `extend(name, base, val)` — define a group by inheriting `base` and
    merging `val` over it.

### Colorscheme

Primary: **catppuccin-mocha** (custom dark base `#12121a`, transparent by default). Falls back to `tokyonight-moon`. Toggle transparency with `<leader>tp`.
