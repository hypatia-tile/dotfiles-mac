---
name: lock-review
description: Review a weekly update-flake-lock pull request and drive it to a merge decision — confirm the diff is lock-only, verify the updated closure, judge the closure diff (where version changes are the expected outcome rather than a red flag), merge by rebase so the dedicated lock commit survives, and name the post-switch check for the tools that moved. Use when a chore(deps) flake.lock PR is open.
---

# lock-review

The `update-flake-lock` workflow opens a `chore(deps): update flake.lock` PR
every Saturday at 06:00 JST. Merging is always manual (ADR 0011, ADR 0012,
ADR 0018) — this is the procedure for deciding.

The entry point is inverted compared to `config-change`: the diff already
exists, and the work is judgment rather than editing.

## Steps

1. **Find the PR and check it out.**
   `gh pr list --state open --label dependencies`, then
   `gh pr checkout <n>`. The workflow reuses the branch
   `update_flake_lock_action` each week.

2. **Confirm the diff is lock-only.**
   `git diff main... --stat` must show `flake.lock` and nothing else. Anything
   else on the branch means the workflow misfired — stop and report.

3. **Verify with `preflight`, with one criterion inverted.** Run the skill; do
   not restate its steps. Its step 5 treats a package version change as a red
   flag, because nothing should move when the lock is untouched. Here the lock
   *is* the change, so version movement across the closure is the expected
   outcome. Judge these instead:
   - every moved node is an upstream version bump of something the flake
     already had — no unexplained **additions or removals**;
   - the net closure size change is plausible. Bootstrap paths dropping out is
     normal (#41 was ~150 nodes and −0.5 GiB); a large unexplained gain is not;
   - **re-run preflight step 1 under the new toolchain.** `nixfmt`, `statix`
     and `deadnix` are themselves in the closure, and a formatter bump can make
     previously-clean `*.nix` files fail CI.
   - the eval warning `nixfmt-rfc-style is now the same as pkgs.nixfmt` is a
     rename alias, harmless until the attribute is actually renamed upstream —
     at which point `modules/home/packages.nix` needs the new name and this
     stops being a lock-only change.

4. **Record the notable bumps.** Name the packages the owner actually uses
   daily with old → new versions. A wall of 150 nodes is not reviewable; a
   dozen named bumps is.

5. **Report, and leave the merge to the owner.** Merge with **`--rebase`,
   never `--squash`**: ADR 0011 requires the lock update to survive as its own
   dedicated commit.
   `! gh pr merge <n> --rebase`

6. **Name the post-switch check.** After the owner's
   `sudo darwin-rebuild switch --flake .#Kazukis-MacBook-Air`, the check is
   driven by *what moved*: start each daily tool whose version changed and
   confirm it runs — Neovim starts clean against its shipped `lazy-lock.json`,
   and the others report the new version. Use the actual names from step 4,
   not a generic instruction.

## Rules

- Never push, never merge, never `darwin-rebuild switch` — those are the
  owner's (ADR 0003, ADR 0008).
- Never run `nix flake update`. Updates come from the workflow or the owner
  (ADR 0011, ADR 0018); build and check invocations still pass
  `--no-update-lock-file`.
- A genuine breakage is a reason to **hold** the PR, not to rerun it until it
  passes. Holding a week costs nothing — the next scheduled run supersedes it.
- Merged is not applied. Until the owner switches, the machine is still on the
  old closure; say so explicitly in the report.
