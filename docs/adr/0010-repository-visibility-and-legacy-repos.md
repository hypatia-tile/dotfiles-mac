# 0010. Repository stays public; legacy repos archived after stability

- Status: Proposed
- Date: 2026-07-13

## Context

`dotfiles-mac` already exists on GitHub as public, as do both legacy
repositories. Flipping visibility mid-migration would require full-history
secret audits before re-publishing.

## Decision

- `dotfiles-mac` remains **public**. The public-by-default posture keeps the
  "no secrets ever" discipline (ADR 0009) permanently active.
- Legacy repositories (`hypatia-tile/dotfiles`, `hypatia-tile/nix-darwin`)
  stay read-only during migration. After cutover plus a 2–4 week stability
  window, both are archived on GitHub. Local clones may remain.

## Consequences

- No visibility transitions, no re-publication audits.
- Archiving ends the dual-source-of-truth period at the GitHub level while
  preserving history and rollback reference material. Archiving is
  reversible.
