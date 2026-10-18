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
   `main`; the working tree is clean. If it is not, commit what belongs to
   the change first (ADR 0036) and name the commits in the report. Run
   `bin/hooks-health.sh`: the
   owner's push runs the `pre-push` gates only if it passes. If it fails,
   say so before asking for the push, and point to `manual-setup`.
2. **Ask the owner to push** (never push yourself):
   suggest `! git push -u origin <branch>`. Start a background wait:
   `until git ls-remote origin <branch> | grep -q <head-sha>; do sleep 15; done`.
3. **Create the PR** with `gh pr create` once the push lands:
   - Title: a Conventional Commit subject, however many commits the branch
     has: the head commit's subject, or a summary in the same form. A squash
     merge makes the title the commit's subject, so commitlint checks it in
     "Docs & commit hygiene" (#249).
   - Body: `## Summary` (what and why, per commit), a `## Verification`
     section stating what was checked (preflight results, lint,
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
   - **A failed title.** Fix it with `gh pr edit <n> --title …`. Editing the
     title starts no run, and `gh run rerun` checks the old title again, so a
     new run has to be started (#249):
     1. Check that the merge ref GitHub tests is current. Run
        `git fetch origin main`, then `git fetch origin refs/pull/<n>/merge`
        as a separate command (`FETCH_HEAD` names the first ref of a fetch),
        and compare `git rev-parse FETCH_HEAD^1` with
        `git rev-parse origin/main`.
     2. If they match, hand the owner `! gh pr close <n> && gh pr reopen <n>`.
     3. If they differ, closing and reopening would test the old base (#154).
        Hand the owner `! gh pr update-branch <n> --rebase` instead: moving
        the head recomputes the merge ref and starts a run.
5. **Report**: state mergeability, suggest `! gh pr merge <n> --squash`
   (or `--rebase` when separate commits should survive, e.g. a dedicated
   input-update commit per ADR 0011), and name any post-merge owner step
   (switch, verification).
   - When the change needs a switch, name `bin/running-main-check.sh` as the
     way to confirm the machine came to rest on `main`. If the owner already
     switched from the branch (ADR 0022), that usually satisfies the invariant
     on its own: the closure is content-addressed, so a squash-merge of an
     unchanged tree produces the identical store path. It drifts when the tree
     really differs — review edits on the PR, or `main` having moved ahead —
     which is exactly when it is worth knowing.

## Rules

- Never push, never merge, never `darwin-rebuild switch` — those are the
  owner's (ADR 0003, ADR 0008).
- One PR per concern; if unrelated changes are mixed on the branch, stop
  and say so instead of shipping them together.
- A `chore(deps): update flake.lock` PR is opened by the weekly workflow, not
  from a local branch — it is reviewed with `lock-review`, not shipped here.
