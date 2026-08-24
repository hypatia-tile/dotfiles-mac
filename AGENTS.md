# AGENTS.md

Rules for any coding agent working in this repository. This file is the
source of truth for them (ADR 0019); `CLAUDE.md` and any future
tool-specific file (`GEMINI.md`, …) point here and add only what is specific
to that tool. Adding an agent must not fork the rules.

Start from `docs/README.md`: it is the index of every document and skill, and
it marks which documents describe the current system and which are records of
the 2026-07 migration.

## What this repository is

The macOS configuration for `Kazukis-MacBook-Air`, as a single Nix flake:
nix-darwin for the system layer, Home Manager (as a nix-darwin module) for
everything user-facing. It has been the live single source of truth since the
2026-07-14 cutover (ADR 0015, finalized by ADR 0018).

## Hard rules

- **Never run `darwin-rebuild switch`, any activation script, or `sudo`.**
  Your work is build-only — `nix flake check`, `darwin-rebuild build`, closure
  diff. Applying is the owner's manual step (ADR 0003, ADR 0015). A merged
  change is not an applied change, and saying otherwise is a reporting error.
- **Never commit or push automatically.** Prepare the change and a proposed
  Conventional Commit message; commit only when explicitly instructed, and
  never push — the owner pushes and merges.
- **The legacy repositories are read-only.** `~/github/dotfiles` and
  `~/github/nix-darwin` are archived rollback material (ADR 0010, ADR 0018)
  and must never be modified. Do not run their `bin/dot-link.sh`.
- **No secrets in this repository**, ever (ADR 0009). Record a secret-bearing
  path by filename only; never read its contents.
- **All repository artifacts are in English** — documents, code, comments,
  commit messages, PR bodies. Conversation with the owner may be in Japanese.

## How work is organised

- **Procedures live in skills, not in documents** (ADR 0019). They are written
  as `.claude/skills/<name>/SKILL.md`. Claude Code loads them automatically;
  other agents should read the relevant file directly. Documents index and
  explain; they do not restate steps. If you find yourself copying a procedure
  into a document, that is the mistake this rule exists to prevent.
- **Run `preflight` before proposing a PR.** It mirrors every required CI gate
  locally. Skipping it has round-tripped PRs through CI on trivial format
  failures.
- Work on short-lived feature branches off `main`, with Conventional Commits.
  One concern per branch.
- **ADRs** live in `docs/adr/NNNN-slug.md` (MADR-lite) and always start as
  `Status: Proposed`; only the owner promotes one to Accepted. Existing ADRs
  are never edited — a changed decision gets a new ADR that supersedes the
  old one. Use the `adr-new` skill.
- **`flake.lock` moves only in dedicated commits** (ADR 0011). The weekly
  workflow opens the PRs and merging is always manual. Build and check
  invocations pass `--no-update-lock-file` so they never mutate the lock as a
  side effect; ad-hoc `nix flake update` is denied in tooling.
- **Deferred work lives in GitHub Issues**, not as TODOs in documents
  (ADR 0019). Before starting a change, check `gh issue list` — the reason
  something was postponed is usually already written down.

## Working notes

Lessons that cost something to learn and are not tied to one procedure.

- **Verify empirically; do not conclude from inference.** Confirm a claim
  about the running system with a real query before stating it. Do not declare
  a tool "not running" or a layer "fine" from a single check — and remember
  macOS process names are case-sensitive, so `pgrep -x aerospace` is a false
  negative for the `AeroSpace` binary. Chase asymmetries (one chord works,
  its neighbour does not) to a concrete cause. The `keybinding-doctor` skill
  applies this to key interception specifically.
- **Check the tail of files you write.** The file-writing tool occasionally
  appends a stray closing tag (e.g. `</content>`) to a file it creates, which
  then breaks Nix evaluation or lint. `grep -rn '</content>' .` over the
  changed tree catches it; `preflight` includes the scan.
