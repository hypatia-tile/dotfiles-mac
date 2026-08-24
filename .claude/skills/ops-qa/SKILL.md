---
name: ops-qa
description: Answer questions about operating this repository (change workflow, Home Manager behavior, CI, cutover history, Nix specifics), grounded in the repository docs and skills rather than memory. Use when the owner asks how or why something works here, or what the procedure for something is.
---

# ops-qa

Answer an operations question from the repository's own record rather than
from memory.

## Steps

1. Search in this order and ground the answer in what you find:
   1. `docs/README.md` — the index; it says which document or skill owns the
      answer and whether a document describes the current system or the
      2026-07 migration.
   2. `.claude/skills/*/SKILL.md` — **procedures live here** (ADR 0019). A
      "how do I…" question is almost always answered by a skill, not a doc.
   3. `docs/operations.md` — day-to-day semantics and hard-won behavior.
   4. `docs/adr/` — the decisions and their rationale.
   5. `docs/rollback.md` — recovery.
   6. `gh issue list --state open` — deferred work. If the question is "why
      isn't X done", the answer is usually a filed issue with the reason.
   7. Historical records — `docs/runbook.md`, `docs/design/flake-design.md`,
      `docs/requirements.md`, `docs/discovery/`. Useful for "why was it built
      this way", but **say explicitly that these describe the migration, not
      the current system**; some of their content is knowingly outdated.
   8. `git log` / merged PRs — how something was actually done.
2. Answer in the language of the conversation, but **cite the file (and
   section) the answer comes from** so the owner can read the primary
   source. Quote the relevant passage when it is short.
3. If the docs and reality might have diverged, verify against the live
   system with read-only commands before answering.
4. If the answer is **not** in the record, say so explicitly — do not present
   reconstruction as documentation — answer from the repository state and
   history as best you can, and offer to close the gap in the right place:
   - a missing **procedure** belongs in a skill, new or existing;
   - a missing piece of **behavior or semantics** belongs in
     `docs/operations.md`;
   - something **not done yet** belongs in a GitHub issue.

## Rules

- Read-only: this skill never changes the system or the repository (except a
  documentation addition the owner approves in step 4).
- Do not guess procedures that are safety-relevant (anything involving
  `switch`, rollback, or the archived legacy repositories) — quote the source
  or decline.
