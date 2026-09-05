---
name: preflight
description: Mirror the required CI gates locally before pushing — nixfmt/statix/deadnix, markdownlint, flake check, system closure build, closure diff against the running system, Home Manager collision check, and a secret scan. Use before merging any flake or config change. Never switches or activates.
---

# preflight

Build-and-lint verification of this repository against the running system
(ADR 0003), mirroring every required CI gate so failures are caught **before**
pushing (CI has round-tripped on format/lint that a local pass would have
caught). **Under no circumstances run `darwin-rebuild switch`, any activation
script, or `sudo`.** If a step fails, report and stop — do not "fix" by
activating anything.

This is the standing gate for every change; `config-change` delegates its
verification here rather than restating it (ADR 0019).

## Steps

Run from the repository root. Always pass `--no-update-lock-file`: lock updates
land as dedicated commits (ADR 0011), so a check or build must never mutate the
lock — a lock modification here is itself a failure. Steps 1–2 mirror the CI
lint jobs and are cheap, so run them first to fail fast.

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
     local-only false positive; a step is failing only on rules CI's version
     would also raise.
   - Commit messages must be Conventional Commits (CI runs commitlint against
     `commitlint.config.mjs`):
     `nix run nixpkgs#commitlint -- --from origin/main --to HEAD`
   - The file-writing tool occasionally appends a stray closing tag to a file
     it creates, which then breaks Nix evaluation or lint. Scan the changed
     tree: `grep -rn '</content>' .`
3. **Flake check**
   `nix flake check --no-update-lock-file`
4. **Build every host closure**
   For each attr in `darwinConfigurations` (currently
   `Kazukis-MacBook-Air`):
   `nix build .#darwinConfigurations.<host>.system --no-update-lock-file -o result`
5. **Closure diff**
   `nix store diff-closures /run/current-system ./result`
   Present the full diff. A package *version* change is a red flag here: this
   check does not touch the lock, so nothing should move. The one exception is
   a deliberate `flake.lock` update, which is reviewed with the `lock-review`
   skill and inverts this criterion. Additions and removals must map to the
   change under review.
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

## Scope shortcuts

Steps 1, 3, 4, 5 and 6 all depend on `*.nix`, `flake.lock` or `config/**`
having changed — the same paths CI's *Detect closure-affecting changes* job
filters on. For a documentation-only change, run steps 2 and 7 and state that
the rest do not apply; CI will report the build job as *skipping*, which still
satisfies the required check.

## Report

End with a pass/fail table for the steps you ran and an explicit statement of
whether the tree meets the CI-gate, collision, and secret criteria. Never
conclude with a recommendation to switch — applying is the owner's manual
decision.
