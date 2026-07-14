# 0015. Cutover to the consolidated flake

- Status: Proposed
- Date: 2026-07-14

## Context

Implementation phases 1–3 (flake-design §6) are merged: the skeleton
(PR #4), the vendored dotfile payloads with Home Manager placement (PR #5),
and the Homebrew declarations with cleanup (PR #6). Every phase passed the
build-only verification suite with `flake.lock` frozen: the closure diff
against the running system contains only the intended deltas (texlive and
its dependencies plus alejandra out; the config payloads and the
`nvim-config` input in; zero package-version changes), the collision check
lists exactly the eight dot-link symlinks plus the inventoried unmanaged
files (`~/.zshenv`, `~/.config/nix`, `~/.config/lazygit`), and the secret
scans are clean.

ADR 0003 requires that the switch from the legacy dot-link + nix-darwin
regime to this repository is a deliberate, owner-executed step gated on a
dedicated ADR and a completed runbook. The runbook (§2) is now complete,
including the pre-switch snapshot, collision preparation, smoke tests, and
the two-layer rollback.

## Decision

Cut over this machine (`Kazukis-MacBook-Air`) to the consolidated flake:
the owner runs `darwin-rebuild switch --flake .#Kazukis-MacBook-Air` from
`main`, following `docs/runbook.md` §2 exactly. From that point this
repository is the single source of truth for the system and user
configuration; `dot-link.sh` is retired and the legacy repositories become
rollback material only.

Sign-off recorded by accepting this ADR:

- diff-closures review: _TBD (owner initials + date at acceptance)_
- runbook §1 pass on the cutover commit: _TBD (commit hash)_

## Consequences

- Every configuration change now requires a commit and `darwin-rebuild
  switch`; ad-hoc edits of files under `~/.config` are no longer possible
  (accepted in ADR 0001).
- First activation removes the cask `aquaskk` and formulas `libidn2`,
  `nettle`, `p11-kit`, and backs up the dot-link symlinks as `*.hm-bak`.
- The legacy repositories must stay untouched during the 2–4 week
  stability window; archiving (ADR 0010) and the first `nix flake update`
  (ADR 0011) only happen after it.
- Rollback stays available at two layers (generation rollback, legacy
  restore) as documented in runbook §3.
