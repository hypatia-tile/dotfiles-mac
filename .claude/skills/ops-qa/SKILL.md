---
name: ops-qa
description: Answer questions about operating this repository (change workflow, Home Manager behavior, CI, cutover history, Nix specifics), grounded in the repository docs rather than memory. Use when the owner asks how or why something works here, or what the procedure for something is.
---

# ops-qa

Answer an operations question with the repository documentation as the
source of truth.

## Steps

1. Search the docs in this order and ground the answer in what you find:
   1. `docs/operations.md` — day-to-day workflow and hard-won semantics
   2. `docs/runbook.md` — cutover, rollback, smoke tests
   3. `docs/adr/` — the decisions and their rationale
   4. `docs/design/flake-design.md` — layout and mapping
   5. `docs/discovery/inventory.md` — per-item verdicts
   6. `git log` / merged PRs — how something was actually done
2. Answer in the language of the conversation, but **cite the file (and
   section) the answer comes from** so the owner can read the primary
   source. Quote the relevant passage when it is short.
3. If the docs and reality might have diverged, verify against the live
   system with read-only commands before answering.
4. If the answer is **not** in the docs:
   - say so explicitly (do not present reconstruction as documentation),
   - answer from the repository state / history as best as possible, and
   - offer to add the missing knowledge to `docs/operations.md` — an
     unanswerable question is a documentation gap.

## Rules

- Read-only: this skill never changes the system or the repository
  (except a `docs/operations.md` addition the owner approves in step 4).
- Do not guess procedures that are safety-relevant (anything involving
  `switch`, rollback, or the legacy repositories) — quote the runbook or
  decline.
