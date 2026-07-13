# 0005. Homebrew: Nix-first, brew as a declared exception lane

- Status: Proposed
- Date: 2026-07-13

## Context

The old repo already declares Homebrew via the nix-darwin `homebrew` module
(casks: hammerspoon, aerospace, emacs; brews: llvm, make, cmake, zsh-abbr),
but cleanup is not enforced and the live system has drifted: cask `aquaskk`
and several orphaned formulas are undeclared, and the installed cask is
`emacs-app` while the declaration says `emacs`.

## Decision

- CLI tools default to nixpkgs (via Home Manager `home.packages`,
  see ADR 0006).
- Homebrew is reserved for (a) GUI casks and (b) packages genuinely requiring
  Homebrew's macOS-specific builds (e.g. llvm). Everything brew-managed is
  declared in the nix-darwin `homebrew` module.
- `homebrew.onActivation.cleanup` is enabled, so undeclared brew packages are
  removed on activation.

## Consequences

- Declarative parity between brew reality and repo declarations.
- **Warning:** with cleanup enabled, currently-undeclared items (notably
  `aquaskk`) will be uninstalled at first activation unless the discovery
  verdict adds them to the declaration. The `emacs`/`emacs-app` name mismatch
  must also be resolved in the inventory.
