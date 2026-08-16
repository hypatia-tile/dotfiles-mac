# 0018. Finalize the migration: archive legacy repos, unfreeze the lock, lift migration-era guardrails

- Status: Proposed
- Date: 2026-08-16

## Context

Cutover to the consolidated flake completed on 2026-07-14 (ADR 0015). This
repository has been the single source of truth for the system and user
configuration for over four weeks — past the 2–4 week stability window that
ADR 0010 and ADR 0011 gate the remaining post-cutover actions on
(`docs/runbook.md` §4).

Two things still reflect a "migration in progress" state that no longer holds:

- The `runbook` §4 post-cutover actions are all unstarted: the weekly
  `update-flake-lock` workflow schedule is commented out, both legacy
  repositories are still unarchived and public, and no `nix flake update` has
  run since the lock was inherited from the legacy flake.
- Several guardrails were written to hold only "until cutover" or "during
  migration" — the `flake.lock` freeze and the framing of the legacy repos as
  live read-only sources — but their gating condition has passed.

The stability window elapsing is the trigger to execute those decisions and
retire the migration-era framing, while keeping the permanent safety
boundaries intact.

## Decision

Execute the finalization already decided by prior ADRs, and record the
guardrail changes here:

- Archive `hypatia-tile/dotfiles` and `hypatia-tile/nix-darwin` on GitHub
  (ADR 0010). Local clones remain as rollback material.
- Enable the weekly `update-flake-lock` workflow schedule and unfreeze the
  lock: lock updates now land as dedicated commits, the workflow opens PRs
  automatically, and merging stays manual (ADR 0011, ADR 0012). The first
  `nix flake update` is the owner's, in a dedicated PR.
- Lift the migration-era freeze wording from `CLAUDE.md`, the
  `migration-check` skill, and `docs/`. This supersedes the "until cutover"
  clause of ADR 0003 for the `flake.lock` freeze only, and amends the
  guardrail set of ADR 0013.

The following guardrails are **retained** — they are permanent safety, not
migration-era freezes:

- Claude never runs `darwin-rebuild switch`, any activation script, or `sudo`;
  applying is the owner's manual step (ADR 0015, `docs/operations.md` §1).
- Claude never commits or pushes automatically; the owner pushes.
- No secrets in this repository, ever (ADR 0009); English-only artifacts.
- Build and check invocations still pass `--no-update-lock-file` so they never
  mutate the lock as a side effect; the `nix flake update` tooling deny stays
  (updates come from the owner or the workflow, never an ad-hoc agent run).
- The archived legacy repositories stay read-only (rollback reference).

## Consequences

- `flake.lock` now moves deliberately: dedicated commits plus weekly workflow
  PRs, merge always manual. Package-version changes in a closure diff are
  expected only when reviewing such a PR; unexpected ones remain a red flag.
- The dual-source-of-truth period ends at the GitHub level (archiving is
  reversible; history and rollback material are preserved).
- `migration-check` becomes the steady-state CI-mirror gate rather than a
  pre-cutover check; its name is now a mild misnomer, left for a later
  cleanup.
- The two-layer rollback (generation rollback, legacy restore) remains
  available; archiving does not remove it.
