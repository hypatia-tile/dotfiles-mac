# 0012. CI: everything that fits runs in GitHub Actions, as required checks

- Status: Accepted
- Date: 2026-07-13

## Context

The repository is public on GitHub (free Actions minutes, arm64 macOS
runners available), and the owner's policy is "everything that can go into
CI goes into CI". CI must respect the safety boundary: build-only, never
activation (ADR 0003).

## Decision

Four job groups in GitHub Actions:

1. **Build/eval** (macOS arm64 runner): `nix flake check
   --no-update-lock-file` plus `nix build` of every
   `darwinConfigurations.*.system` attribute. The frozen lock makes this an
   integrity check of all input hashes (ADR 0011). CI never runs `switch`.
2. **Nix lint/format** (Linux runner): `nixfmt-rfc-style --check`, `statix`,
   `deadnix`. Note: the legacy repo used alejandra; new code in this repo is
   formatted with nixfmt-rfc-style (the upstream-official formatter).
3. **Secret scan**: gitleaks over full history (backs ADR 0009).
4. **Docs/commit hygiene**: markdownlint, commitlint (Conventional Commits,
   ADR 0008), shellcheck.

Caching: `cache-nix-action` on the GitHub Actions cache, plus
`cache.nixos.org` and the nix-community cachix as substituters. No external
accounts or repository secrets.

Enforcement: a `main` ruleset forbids direct pushes and marks all jobs as
required status checks; self-merge only when green.

Post-cutover: a weekly `update-flake-lock` workflow opens lock-update PRs;
merge is always manual. Disabled (manual trigger only) until cutover.

## Consequences

- A broken flake cannot reach `main`.
- macOS runner minutes are the main cost; caching and the frozen lock keep
  builds mostly substituted.
