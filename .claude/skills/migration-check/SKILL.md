---
name: migration-check
description: Run the build-only migration verification suite — flake check, system closure build, closure diff against the running system, Home Manager collision check, and a secret scan. Use before merging flake changes or preparing cutover. Never switches or activates.
---

# migration-check

Build-only verification of this repository against the running system
(ADR 0003). **Under no circumstances run `darwin-rebuild switch`, any
activation script, or `sudo`.** If a step fails, report and stop — do not
"fix" by activating anything.

## Steps

Run from the repository root. Always pass `--no-update-lock-file` (the lock
is frozen during migration, ADR 0011 — a lock modification is itself a
failure).

1. **Flake check**
   `nix flake check --no-update-lock-file`
2. **Build every host closure**
   For each attr in `darwinConfigurations` (currently
   `Kazukis-MacBook-Air`):
   `nix build .#darwinConfigurations.<host>.system --no-update-lock-file -o result`
3. **Closure diff**
   `nix store diff-closures /run/current-system ./result`
   Present the full diff. During migration any package *version* change is a
   red flag (lock is frozen); additions/removals must map to inventory
   verdicts.
4. **Collision check**
   Enumerate the files the built configuration will place in `$HOME`
   (e.g. via `nix eval` of `home-manager` file attrs, or by inspecting
   `./result`'s home-files). For each target that already exists in `$HOME`
   as a regular file or foreign symlink, report it. Verify
   `backupFileExtension` is configured before calling this step passed.
5. **Secret scan**
   `gitleaks detect --source . --no-banner` if gitleaks is available;
   otherwise grep the working tree for obvious patterns
   (`BEGIN .* PRIVATE KEY`, `ghp_`, `github_pat_`, `AKIA[0-9A-Z]{16}`,
   `oauth_token`).

## Report

End with a pass/fail table for the five steps and an explicit statement of
whether the tree meets the pre-cutover criteria in `docs/runbook.md`
section 1. Never conclude with a recommendation to switch — cutover is the
owner's manual decision.
