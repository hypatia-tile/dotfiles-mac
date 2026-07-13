# 0008. Git workflow: short-lived branches, Conventional Commits

- Status: Proposed
- Date: 2026-07-13

## Context

Solo-maintained repository, but the migration proceeds in phases whose
history should map cleanly to decisions, and `main` must never hold a broken
flake (a broken `main` is exactly what the cutover machine would consume).

## Decision

- `main` is protected; work happens on short-lived feature branches
  (e.g. `docs/adr-0001`, `feat/zsh-module`) and is self-merged when CI is
  green (ADR 0012).
- Commit messages follow Conventional Commits, in English.
- Claude Code prepares changes and proposes commit messages but commits only
  on explicit instruction, and never pushes (enforced via
  `.claude/settings.json`: `git push` denied, `git commit` requires
  confirmation).

## Consequences

- History is structured and mappable to ADRs.
- The mechanical guard implements the "no automatic commits" rule instead of
  relying on session discipline.
