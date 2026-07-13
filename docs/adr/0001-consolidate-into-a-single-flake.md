# 0001. Consolidate into a single, fully store-managed flake

- Status: Proposed
- Date: 2026-07-13

## Context

macOS configuration is split across two repositories: `~/github/dotfiles`
(symlink-based, force-overwrite `dot-link.sh` using `rm -rf` + `ln -s`) and
`~/github/nix-darwin` (flake: nix-darwin with Home Manager integrated as a
darwin module). The old Home Manager config deliberately disables
`programs.zsh/tmux/kitty/alacritty` to avoid colliding with dot-link symlinks —
a sign of the two systems working around each other.

## Decision

dotfiles-mac becomes the single entry point: one flake, with dotfile payloads
vendored into this repository and placed by Home Manager (`xdg.configFile`,
`home.file`). `dot-link.sh` is retired.

All managed files are **fully store-managed**. No `mkOutOfStoreSymlink`
escape hatches: every change, including editor config tweaks, is applied via
`darwin-rebuild switch` (performed manually by the owner, see ADR 0003).

## Consequences

- Declarative, reproducible, rollback-capable configuration; the
  force-overwrite symlink script and its `rm -rf` risk disappear.
- Editing iteration on frequently-changed configs (e.g. Neovim) requires a
  rebuild per change. This trade-off was made knowingly, preferring purity.
- The existing HM `programs.*` disablements can be reverted or replaced by
  explicit file placement in this repository.
