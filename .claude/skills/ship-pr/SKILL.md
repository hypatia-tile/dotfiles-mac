---
name: ship-pr
description: Drive a committed feature branch through push, PR creation, and CI to a mergeable state — waiting for the owner's push, creating the PR with the house-style body, watching the checks, and reporting. Use after commits exist on a branch and the owner wants a PR.
---

# ship-pr

Take the current feature branch from "committed locally" to "PR green and
mergeable". The owner pushes and merges; this skill does everything in
between.

## Steps

1. **Confirm the branch state**: commits exist on a feature branch off
   `main`; the working tree is clean. Never commit here — committing
   requires its own explicit instruction.
2. **Ask the owner to push** (never push yourself):
   suggest `! git push -u origin <branch>`. Start a background wait:
   `until git ls-remote origin <branch> | grep -q <head-sha>; do sleep 15; done`.
3. **Create the PR** with `gh pr create` once the push lands:
   - Title: the head commit's Conventional Commit subject (or a summary
     when the branch has several commits).
   - Body: `## Summary` (what and why, per commit), a `## Verification`
     section stating what was checked (migration-check results, lint,
     lock untouched), any owner-attention items, and the
     `🤖 Generated with [Claude Code](https://claude.com/claude-code)` footer.
   - If the change needs a post-merge `darwin-rebuild switch`, say so in
     the body and name the behavioral check the owner should run.
4. **Watch CI** with a background poll of
   `gh pr checks <n> --json name,bucket` until nothing is pending, then
   report every check's result.
   - Docs-only PRs: "Flake check & system closure build" reporting
     **skipping** is expected and still satisfies the required check.
   - A failure in job *setup* with "Service Unavailable" is GitHub
     infrastructure: rerun with `gh run rerun <run-id> --failed` once.
   - A real failure: fetch the failed log, diagnose, and propose the fix;
     do not rerun to make a legitimate failure pass.
5. **Report**: state mergeability, suggest `! gh pr merge <n> --squash`
   (or `--rebase` when separate commits should survive, e.g. a dedicated
   input-update commit per ADR 0011), and name any post-merge owner step
   (switch, verification).

## Rules

- Never push, never merge, never `darwin-rebuild switch` — those are the
  owner's (ADR 0003, ADR 0008).
- One PR per concern; if unrelated changes are mixed on the branch, stop
  and say so instead of shipping them together.
