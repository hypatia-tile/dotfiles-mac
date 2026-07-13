# 0013. Claude Code guardrails and skills

- Status: Accepted
- Date: 2026-07-13

## Context

Much of the migration work is executed with Claude Code. Session discipline
does not survive context resets; repository-level configuration does.

## Decision

- `.claude/settings.json` enforces the safety boundary mechanically:
  - **deny**: `darwin-rebuild switch`/activation, `git push`,
    `nix flake update`, and writes to the two read-only source repositories;
  - **ask**: `git commit` (implements "commit only on explicit instruction");
  - **allow**: the read-only verification commands (`nix flake check`,
    `nix build`, `darwin-rebuild build`, `nix store diff-closures`, `git`
    status/diff/log, `brew list`).
- Two repository skills:
  - `adr-new` — scaffolds the next sequentially-numbered ADR with
    `Status: Proposed`;
  - `migration-check` — runs the full build-only verification suite and
    reports pass/fail; structurally incapable of switching.
- CLAUDE.md restates the rules with their rationale.

## Consequences

- Guardrails persist across sessions and future tooling.
- Bash-level writes to source repos cannot be fully pattern-blocked; the deny
  rules cover the realistic paths and CLAUDE.md covers the rest.
