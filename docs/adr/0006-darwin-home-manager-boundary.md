# 0006. Boundary rule: user-facing goes to Home Manager

- Status: Accepted
- Date: 2026-07-13

## Context

The old repo splits `nix/darwin` (system) from `nix/home` (user) but the rule
was never written down, so placement questions recur.

## Decision

Everything the user consumes — CLI tools, dotfiles, shell, editors — lives in
Home Manager. nix-darwin is restricted to what cannot exist without the
system layer: nix daemon settings, fonts, the `homebrew` module, user
accounts, and OS-level services.

## Consequences

- Placement questions get a mechanical answer.
- The HM layer remains portable if configuration is ever shared with a Linux
  host, without committing to that now.
