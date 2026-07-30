---
name: migration-check
description: Mirror the required CI gates locally before pushing — nixfmt/statix/deadnix, markdownlint, flake check, system closure build, closure diff against the running system, Home Manager collision check, and a secret scan. Use before merging flake changes or preparing cutover. Never switches or activates.
---

# migration-check

Build-and-lint verification of this repository against the running system
(ADR 0003), mirroring every required CI gate so failures are caught **before**
pushing (CI has round-tripped on format/lint that a local pass would have
caught). **Under no circumstances run `darwin-rebuild switch`, any activation
script, or `sudo`.** If a step fails, report and stop — do not "fix" by
activating anything.

## Steps

Run from the repository root. Always pass `--no-update-lock-file` (the lock
is frozen during migration, ADR 0011 — a lock modification is itself a
failure). Steps 1–2 mirror the CI lint jobs and are cheap, so run them first
to fail fast.

1. **Nix format & lint** (mirrors the CI *Nix format & lint* job). Skip if the
   change touches no `*.nix`.
   - `find . -name '*.nix' -not -path './.git/*' -print0 | xargs -0 nix run nixpkgs#nixfmt-rfc-style -- --check`
     (to fix: rerun without `--check`)
   - `nix run nixpkgs#statix -- check .`
   - `nix run nixpkgs#deadnix -- --fail .`
2. **Docs & commit hygiene** (mirrors the CI *Docs & commit hygiene* job).
   - `nix run nixpkgs#markdownlint-cli2 -- '**/*.md'` — the nixpkgs
     markdownlint is newer than CI's pinned `markdownlint-cli2-action@v19`, so
     it raises rules CI does not have (notably **MD060**). Treat MD060 as a
     local-only false positive (`docs/operations.md` §4); a step is failing
     only on rules CI's version would also raise.
   - Commit messages must be Conventional Commits (CI runs commitlint against
     `commitlint.config.mjs`).
3. **Flake check**
   `nix flake check --no-update-lock-file`
4. **Build every host closure**
   For each attr in `darwinConfigurations` (currently
   `Kazukis-MacBook-Air`):
   `nix build .#darwinConfigurations.<host>.system --no-update-lock-file -o result`
5. **Closure diff**
   `nix store diff-closures /run/current-system ./result`
   Present the full diff. During migration any package *version* change is a
   red flag (lock is frozen); additions/removals must map to inventory
   verdicts.
6. **Collision check**
   Enumerate the files the built configuration will place in `$HOME`
   (e.g. via `nix eval` of `home-manager` file attrs, or by inspecting
   `./result`'s home-files). For each target that already exists in `$HOME`
   as a regular file or foreign symlink, report it. Verify
   `backupFileExtension` is configured before calling this step passed.
7. **Secret scan**
   `gitleaks detect --source . --no-banner` if gitleaks is available;
   otherwise grep the working tree for obvious patterns
   (`BEGIN .* PRIVATE KEY`, `ghp_`, `github_pat_`, `AKIA[0-9A-Z]{16}`,
   `oauth_token`).

## Report

End with a pass/fail table for the seven steps and an explicit statement of
whether the tree meets the pre-cutover criteria in `docs/runbook.md`
section 1. Never conclude with a recommendation to switch — cutover is the
owner's manual decision.
