# 0002. Migration scope and discovery process

- Status: Accepted
- Date: 2026-07-13

## Context

Beyond the two source repositories, `~/.config` contains unmanaged
configuration (fish, helix, lazygit, skk, iterm2, gh, ...), Homebrew has
undeclared packages, and macOS defaults are managed manually. Blindly
migrating everything would fossilize junk; migrating only the repos would
leave silent gaps discovered on the next machine.

## Decision

- Scope baseline: contents of `~/github/dotfiles` and `~/github/nix-darwin`,
  **minus** exclusions (Emacs, Org-mode, ddskk are out of scope).
- A one-shot, read-only discovery scan enumerates: both repos, unmanaged
  `~/.config` entries, undeclared Homebrew packages, `~/Library/LaunchAgents`,
  and `$HOME` dotfiles. Results live in `docs/discovery/inventory.md` as a
  verdict table (item / current owner / proposal / owner's verdict).
- Design and implementation do not start until every inventory row has an
  owner verdict.
- macOS `system.defaults` are out of the initial migration scope. Current
  values are recorded during discovery
  (`docs/discovery/macos-defaults-snapshot.md`); declarative adoption happens
  in a later phase under its own ADR.

## Consequences

- Scope is fixed before flake structure is designed, avoiding rework.
- Unmanaged configs get an explicit include/exclude/defer decision instead of
  being silently lost or silently fossilized.
