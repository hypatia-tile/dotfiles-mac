# 0003. Safety boundary: build-only until a manual cutover

- Status: Proposed
- Date: 2026-07-13

## Context

The first `darwin-rebuild switch` from this repository replaces the live
system generation and Home Manager will collide with symlinks left by
`dot-link.sh`. This moment is near-irreversible in feel and must not happen
by accident, e.g. as a side effect of an automated session.

## Decision

- During migration, only non-destructive verification is allowed:
  `nix flake check`, `darwin-rebuild build` / `nix build` of the system
  closure, `nix store diff-closures`. Never `switch` or activation.
- Cutover requires: (1) a dedicated cutover ADR accepted by the owner,
  (2) the rollback runbook (`docs/runbook.md`) completed beforehand, and
  (3) the owner personally executing `darwin-rebuild switch`.
- Home Manager collisions are absorbed via `backupFileExtension` (`hm-bak`),
  never by deleting existing files.
- Verification acceptance criteria (all required): flake check passes, system
  closure builds, `nix store diff-closures /run/current-system ./result` is
  visually reviewed, and HM-managed file targets are checked against existing
  `$HOME` files for collisions.

## Consequences

- Verification can run freely and repeatedly with zero system risk.
- The irreversible step is concentrated into a single, explicit, documented
  decision executed by a human.
