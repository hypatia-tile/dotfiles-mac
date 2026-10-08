---
name: preflight
description: Verify a change locally before pushing — run every Git hook stage over the whole tree (the same check scripts CI runs), then judge the closure diff against the running system and the Home Manager collision check. Use before proposing a PR for any change. Never switches or activates.
---

# preflight

The fallback for the Git hooks and the review step after them (ADR 0032).
The gates themselves run on every commit and push once the hooks are
installed; this runs all of them over the whole tree, then does the two
checks that need a reader. **Under no circumstances run
`darwin-rebuild switch`, any activation script, or `sudo`.** If a step fails,
report and stop — do not "fix" by activating anything, and never get past a
failing gate by skipping it.

This is the standing gate for every change; `config-change` delegates its
verification here rather than restating it (ADR 0019).

## Steps

Run from the repository root.

1. **Every gate:** `bin/preflight.sh`. Its header says what it runs. Which
   checks exist, what each runs and which files concern it are decided by
   `lefthook.yml` and the `bin/check-*.sh` scripts, not here. Its first stage
   is `bin/hooks-health.sh`, which fails if the hooks are not installed; the
   fix is the owner's step in `manual-setup`. A failing stage is the finding:
   report the check's own output.
2. **Closure diff.** Link the closure step 1 built, for the host being
   changed (currently `Kazukis-MacBook-Air`), and compare it with the running
   system:
   `nix build .#darwinConfigurations.<host>.system --no-update-lock-file -o result`
   then `nix store diff-closures /run/current-system ./result`.
   Present the full diff. A package *version* change is a red flag here: this
   check does not touch the lock, so nothing should move. The one exception is
   a deliberate `flake.lock` update, which is reviewed with the `lock-review`
   skill and inverts this criterion. Additions and removals must map to the
   change under review.

   **For a payload-only change the expected diff is empty, and that is the
   check.** Since ADR 0021 a link target is a path string, so editing
   `config/**` leaves the closure byte-identical. A closure that *does* move on
   a payload-only change means something still copies that file into the store,
   and is the finding. The verification for the content itself is step 1.
3. **Collision check.** Enumerate the files the built configuration will place
   in `$HOME` (e.g. via `nix eval` of `home-manager` file attrs, or by
   inspecting `./result`'s home-files). For each target that already exists in
   `$HOME` as a regular file or foreign symlink, report it. Verify
   `backupFileExtension` is configured before calling this step passed.

## Intentionally CI-only

Two checks have no local counterpart, and the reason is the trade each
encodes rather than an omission:

- **The pull request's title** is a Conventional Commit, because it becomes
  the squash commit's subject when the branch has more than one commit. It
  exists only once the PR does.
- **Plugin pins do not ride along with other changes (#98)** — report-only,
  and only on pull requests. It needs the PR base SHA and annotates rather
  than fails: the judgement "pins rode along on purpose" is the author's,
  which a gate cannot make. Run `.github/scripts/pins-ride-along.py` by hand
  against a base if you want the same signal before opening the PR.

## Report

End with step 1's pass/fail lines, the closure diff and its judgement, and the
collision result, and state explicitly whether the tree meets the CI-gate,
collision, and secret criteria. Never conclude with a recommendation to
switch — applying is the owner's manual decision.
