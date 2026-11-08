---
name: sibling-lock-review
description: Review the weekly lock PRs of hypatia-tile/emacs-flake (Fridays) and hypatia-tile/nix-packages (Saturdays) from a session here, without writing into either checkout — read the PR with gh, build and evaluate its head by flake reference, check that this host's Emacs is in hypatia-emacs.cachix.org, diff this host's closure with the bumped nix-packages, and hand the run approval and the merge to the owner. Use when either repository has an open chore(deps) flake.lock PR, before this repository's own lock-review.
---

# sibling-lock-review

An Emacs or package bump reaches this Mac through three weekly lock PRs, in
this order (ADR 0039):

1. **emacs-flake**, Fridays: its own `nixpkgs`, checked and built into
   hypatia-emacs.cachix.org by `update.yml` before the PR opens;
2. **nix-packages**, Saturdays: `nixpkgs`, the overlays and `emacs-flake`;
3. **this repository**, Sundays: the `nix-packages` input, with `lock-review`.

This skill is the first two, from a session here. Merging and approving runs
are the owner's, handed over as `! gh …`.

**Never write into a sibling checkout.** No `gh pr checkout`, `git switch` or
build there: read the PR with `gh`, and build or evaluate its head by flake
reference, `github:hypatia-tile/<repository>/<sha>`. Each step below works
whatever branch the checkouts are on. Nothing writes `flake.lock`: the builds
here pass `--no-write-lock-file`.

## emacs-flake

1. **Find the PR and its head.**
   `gh pr list -R hypatia-tile/emacs-flake --state open --head update-flake-lock --json number,headRefOid,body`.
   No PR is normal: `update.yml` opens none when the lock is current, and
   none when its check or build failed. Look at its latest run
   (`gh run list -R hypatia-tile/emacs-flake --workflow update.yml --limit 1`)
   and report a failure: the day `frame-transparency` stops applying is the
   day that run goes red (hypatia-tile/emacs-flake#2).
2. **Confirm the diff is lock-only.**
   `gh pr diff <n> -R hypatia-tile/emacs-flake --name-only` must print
   `flake.lock` alone. Anything else means the workflow misfired: stop and
   report.
3. **Read the update run.** The PR body names the Emacs version move and
   links the run. `gh run view <run-id> -R hypatia-tile/emacs-flake --json conclusion`
   must be `success`: that run checked that the patch applies without fuzz
   and built `.#default` into the cache. It is the PR's gate.
4. **Confirm the cache has the build.**

   ```sh
   out=$(nix eval --raw github:hypatia-tile/emacs-flake/<head>#default.outPath)
   nix path-info --store https://hypatia-emacs.cachix.org "$out"
   ```

5. **Say what reaches this host, and when.** Nothing, yet. The overlay builds
   Emacs from the *consumer's* nixpkgs, so a lock bump here changes this
   host only through nix-packages' Saturday PR, and its Emacs is a cache hit
   only if that PR's nixpkgs gives the same Emacs derivation this PR's CI
   built (#346). Name this PR's new `nixpkgs` revision
   (`nix flake metadata --json github:hypatia-tile/emacs-flake/<head>`) so
   the nix-packages review can compare.
6. **Hand over.** The PR's own `build.yml` run waits for approval, because
   `GITHUB_TOKEN` opened the PR (hypatia-tile/emacs-flake#8). Give the owner
   its page, from
   `gh run list -R hypatia-tile/emacs-flake --workflow build.yml --branch update-flake-lock --limit 1 --json url,status`,
   to approve before merging: a merge without it closes that run as failed.
   Then `! gh pr merge <n> -R hypatia-tile/emacs-flake --squash`, as its lock
   PRs have been merged.

## nix-packages

1. **Find the PR, its head and its base.**
   `gh pr list -R hypatia-tile/nix-packages --state open --label dependencies --json number,headRefOid,baseRefOid`.
2. **Read that repository's own procedure** from its `main` on GitHub, not
   from the checkout, which may be on any branch:
   `gh api repos/hypatia-tile/nix-packages/contents/.claude/skills/lock-review/SKILL.md -H 'Accept: application/vnd.github.raw'`.
   Apply its judgement as written. Its steps that need the checkout are
   replaced by the steps below; do not run them there.
3. **Confirm the diff is lock-only**, as for emacs-flake:
   `gh pr diff <n> -R hypatia-tile/nix-packages --name-only`.
4. **The gates.** Its lock PRs get no CI run of their own. Once its weekly
   workflow runs the gates before opening the PR
   (hypatia-tile/nix-packages#20), read that run's conclusion as in the
   emacs-flake section. Until then, report the gates as **unchecked**, and
   say that its `lock-review`, from a session in that checkout, is what runs
   them.
5. **Diff its check system's closure** by flake reference, in a temporary
   directory, never in either checkout:

   ```sh
   d=$(mktemp -d)
   nix build -o "$d/old" github:hypatia-tile/nix-packages/<base>#checks.aarch64-darwin.darwin
   nix build -o "$d/new" github:hypatia-tile/nix-packages/<head>#checks.aarch64-darwin.darwin
   nix store diff-closures "$d/old" "$d/new"
   ```

   and judge it by that repository's `lock-review`.
6. **Vulnerabilities.** Run `vulns` on the PR's source, which `nix flake
   prefetch` puts in the store:

   ```sh
   src=$(nix flake prefetch --json github:hypatia-tile/nix-packages/<head> | jq -r .storePath)
   vulns repo "$src"
   ```

   Say whether the bump fixes or brings a finding, and name the
   `vulnerability` issue it touches.
7. **This host's Emacs, before building the host.** A miss here is a
   twenty-minute Emacs build in the owner's switch, so check it first:

   ```sh
   e=$(nix eval --raw --no-write-lock-file \
     --override-input nix-packages github:hypatia-tile/nix-packages/<head> \
     .#darwinConfigurations.<host>.pkgs.myEmacs.outPath)
   nix path-info --store https://hypatia-emacs.cachix.org "$e"
   ```

   `<host>` is the `hostname` in `hosts/*.nix`. A miss is a reason to hold
   the PR: compare its `nixpkgs` with emacs-flake's, and say which one has to
   move.
8. **This host's closure with the bump:**

   ```sh
   nix build -o "$d/host-old" --no-update-lock-file .#darwinConfigurations.<host>.system
   nix build -o "$d/host-new" --no-write-lock-file \
     --override-input nix-packages github:hypatia-tile/nix-packages/<head> \
     .#darwinConfigurations.<host>.system
   nix store diff-closures "$d/host-old" "$d/host-new"
   ```

   This is the preview of Sunday's `lock-review` here, judged the same way:
   version movement is expected, unexplained additions or removals are not.
9. **Hand over.** `! gh pr merge <n> -R hypatia-tile/nix-packages --rebase`,
   never `--squash`, so the lock commit survives (its `lock-review`). Merged
   there changes nothing here: this host takes it when its `nix-packages`
   input moves, through this repository's weekly PR and `lock-review`.

## Report

For each PR: its number and head, lock-only or not, the gates' run and
conclusion (or **unchecked**), the cache result, the notable version moves,
the `vulns` result (nix-packages), this host's closure diff and its
judgement (nix-packages), and the `! gh …` steps for the owner.

## Rules

- Never write into the emacs-flake or nix-packages checkout. A change there
  is not a review: from here, nix-packages is changed only through its
  sub-agent (ADR 0038), and emacs-flake only from a session in its
  checkout until its sub-agent exists (ADR 0039).
- Never push, merge, approve a run, or switch. Those are the owner's.
- Never run `nix flake update`.
- A genuine breakage is a reason to hold the PR, not to rerun it until it
  passes. The next week's run supersedes it.
