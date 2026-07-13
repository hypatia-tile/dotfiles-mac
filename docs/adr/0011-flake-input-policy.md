# 0011. Flake inputs: nixpkgs-unstable, lock frozen until cutover

- Status: Proposed
- Date: 2026-07-13

## Context

The old flake tracks `nixpkgs-unstable` with neovim-nightly and rust
overlays. During migration, `nix store diff-closures` against the running
system is a primary verification signal; mixing package-update noise into
that diff would drown out migration-caused changes.

## Decision

- Keep `nixpkgs-unstable` and the existing overlays (subject to inventory
  verdicts).
- Start from the legacy repository's `flake.lock`; the lock is **frozen**
  during migration. All Nix invocations use `--no-update-lock-file`, and
  `nix flake update` is denied in tooling until cutover completes.
- Nix's hash pinning is treated as an integrity check: a stale or tampered
  lock fails CI evaluation rather than silently updating.
- After cutover, lock updates are made in dedicated commits: a weekly
  `update-flake-lock` GitHub Action opens PRs automatically, but merging is
  always manual (ADR 0012). The workflow stays disabled until cutover.

## Consequences

- Closure diffs during migration reflect structural changes only.
- Update cadence is automated post-cutover without surrendering the merge
  decision.
