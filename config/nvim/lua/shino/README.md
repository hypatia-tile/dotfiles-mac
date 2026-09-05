# `lua/shino/` — custom modules

Small, self-contained helpers for this config. Each module's header comment
is the source of truth; the authoritative usage notes live in the
**Custom Modules** section of the top-level `CLAUDE.md`.

## Modules

- **`keymap.lua`** — typed, semantic wrappers over `vim.keymap.set`
  (`map`, `nmap`/`imap`/`vmap`/`xmap` with a required `desc`).
- **`autocmd.lua`** — typed wrappers over `nvim_create_autocmd`/`augroup`
  (`autocmd(event, desc, opts)` with a required `desc`, `group(name)`).
- **`highlight.lua`** — typed wrappers over `nvim_set_hl`
  (`set(name, val)`, `extend(name, base, val)`).
- **`commands.lua`** — user commands. Currently `:InitLua` (open `init.lua`).

Prefer the wrappers over the raw Neovim API: they keep mappings, autocmds,
and highlights self-documenting and preserve LuaLS field completion via
Neovim's own `vim.*.keyset`/`Opts` types.
