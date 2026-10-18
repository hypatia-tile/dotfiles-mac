---
name: take-issue
description: Take an open issue in this repository to committed feature branches, split into stages when it is bigger than one concern, stacked one on the next, and stop before the push with the push order and each PR's title and body ready. Use when the owner asks to work on, implement or finish an issue (the owner may phrase this in Japanese, e.g. "#N を進めましょう", "#N を完遂しましょう").
---

# take-issue

Turn an issue into branches the owner can push. Agents commit without asking
(ADR 0036) and never push, so this skill ends where `ship-pr` begins.

## Steps

1. **Read the issue in full.** Read its body and every comment, the issues
   and comments it links, and its place on the open `Roadmap: …` issue
   (`inbox` says how to find it). A dependency the roadmap names that is
   still open is a reason to stop and say so.
2. **Settle the open points first.** An issue's "What needs deciding" is
   the owner's to decide. Ask, with a recommendation, before writing
   anything that depends on the answer. A point that needs a new decision
   rather than an application of an existing one goes through `adr-new`.
3. **Split it into stages.**
   - **One concern per stage.** A stage is one branch, one PR and one
     squash commit on `main`.
   - **Every stage must leave `main` working on its own.** Payloads are
     links into the working tree (ADR 0034), so each stage is live when it
     is merged, and possibly before.
   - **One stage is the normal case.** Split only when the stages are
     separate concerns, or when one would be too large to review.
4. **Stack the branches.** The first stage branches off `main`, and each
   later stage off the one before it. Name each branch for its own concern,
   as any other branch is named.
5. **Build each stage in order.**
   1. Run `bin/hooks-health.sh` before the session's first commit
      (`AGENTS.md`). If it fails, report it and stop.
   2. Make the change. Commit as you go, with Conventional Commits.
   3. Put `Closes #N` only in the stage that finishes the issue. Earlier
      stages reference it with `#N` in the body.
   4. Run `preflight` on each stage, not just the top one. Each stage
      reaches `main` alone, and CI checks only what it changes.
   5. A fix to an earlier stage is a commit on that stage's branch. Bring
      it up the stack with `git rebase --update-refs` from the top branch.
6. **End on the top branch.** The checkout is the live configuration, so
   the report says which branch it is.
7. **Report and hand over.**
   - Every branch in stack order, with each commit's short hash and
     subject, and the fact that nothing is pushed.
   - The push command, for example
     `! git push -u origin <stage-1> <stage-2>`.
   - Each PR's title, a Conventional Commit subject, and its base: `main`
     for the first stage, the previous stage's branch for the others.
   - Each PR's body. A stacked PR's body says which PR it is stacked on and
     that it merges after that one.

   From the push on, `ship-pr` takes over, including how to merge a stack.

## Rules

- Never push, merge or switch. Those are the owner's (ADR 0003, ADR 0036).
- Do not decide an issue's open points silently. Ask the owner, or record
  the question on the issue.
- Do not widen the scope. Something found along the way that the issue does
  not cover goes to the inbox (`inbox`), not into a stage.
