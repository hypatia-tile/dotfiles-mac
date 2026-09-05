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
3. **Payload content checks** (mirrors the CI *zsh payload syntax* and *nvim*
   jobs). Run the one matching what changed; skip if no payload changed.
   - zsh: `for f in config/zshenv config/zsh/.zshrc config/zsh/.zprofile config/zsh/.zshenv config/zsh/abbr-definitions.zsh config/zsh/modules/*.zsh; do zsh -n "$f" || echo "FAIL $f"; done`
   - nvim: `nix run nixpkgs#stylua -- --check config/nvim/lua/ config/nvim/after/ config/nvim/ftplugin/ config/nvim/init.lua`,
     and `config/nvim/bin/check` for a headless startup (slow on a cold plugin
     cache; it restores to `lazy-lock.json`).
   These are the steps that carry the weight for a payload change, because
   step 5 cannot see one — see the note there.

4. **Flake check**
   `nix flake check --no-update-lock-file`
5. **Build every host closure**
   For each attr in `darwinConfigurations` (currently
   `Kazukis-MacBook-Air`):
   `nix build .#darwinConfigurations.<host>.system --no-update-lock-file -o result`
6. **Closure diff**
   `nix store diff-closures /run/current-system ./result`
   Present the full diff. A package *version* change is a red flag here: this
   check does not touch the lock, so nothing should move. The one exception is
   a deliberate `flake.lock` update, which is reviewed with the `lock-review`
   skill and inverts this criterion. Additions and removals must map to the
   change under review.

   **For a payload-only change the expected diff is empty, and that is the
   check.** Since ADR 0021 a link target is a path string, so editing
   `config/**` leaves the closure byte-identical. A closure that *does* move on
   a payload-only change means something still copies that file into the store,
   and is the finding. The verification for the content itself is step 3.
7. **Collision check**
   Enumerate the files the built configuration will place in `$HOME`
   (e.g. via `nix eval` of `home-manager` file attrs, or by inspecting
   `./result`'s home-files). For each target that already exists in `$HOME`
   as a regular file or foreign symlink, report it. Verify
   `backupFileExtension` is configured before calling this step passed.
8. **Secret scan**
   `gitleaks detect --source . --no-banner` if gitleaks is available;
   otherwise grep the working tree for obvious patterns
   (`BEGIN .* PRIVATE KEY`, `ghp_`, `github_pat_`, `AKIA[0-9A-Z]{16}`,
   `oauth_token`).

## Scope shortcuts

Steps 1, 4, 5, 6 and 7 depend on `*.nix` or `flake.lock` having changed —
the same paths CI's *build* filter uses. Step 3 depends on `config/**`.
`config/**` is deliberately **not** in the build filter (ADR 0022): payload
content cannot move the closure, so a payload-only change runs steps 2, 3 and
8, and CI reports the macOS build as *skipping*, which still satisfies the
required check. For a documentation-only change, run steps 2 and 8 alone.

## Report

End with a pass/fail table for the steps you ran and an explicit statement of
whether the tree meets the CI-gate, collision, and secret criteria. Never
conclude with a recommendation to switch — applying is the owner's manual
decision.
