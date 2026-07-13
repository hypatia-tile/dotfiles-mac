# Requirements

Requirements for migrating the macOS configuration from
`~/github/dotfiles` and `~/github/nix-darwin` into this repository.
Decided in the grilling session of 2026-07-13. Each requirement references
the ADR that realizes it.

## Goal

- **R-01** The end state is a single flake (nix-darwin + Home Manager as a
  darwin module) that fully replaces both legacy repositories. `dot-link.sh`
  is retired. → ADR 0001
- **R-02** All managed files are store-managed; no out-of-store symlink
  exceptions. → ADR 0001
- **R-03** Configurations are hostname-keyed with shared modules;
  `aarch64-darwin` only. → ADR 0004

## Scope

- **R-04** Scope baseline is the two legacy repositories minus exclusions;
  Emacs, Org-mode, and ddskk are out of scope. → ADR 0002
- **R-05** A read-only discovery scan produces
  `docs/discovery/inventory.md`; every row needs an owner verdict before
  design proceeds. → ADR 0002
- **R-06** macOS `system.defaults` are recorded but not migrated initially;
  declarative adoption is a later phase. → ADR 0002

## Safety

- **R-07** Legacy repositories are read-only for the entire migration.
  → ADR 0013 (enforced), ADR 0010 (lifecycle)
- **R-08** Only build-level verification until cutover; `darwin-rebuild
  switch` is executed exclusively by the owner, gated on an accepted cutover
  ADR and a completed rollback runbook. → ADR 0003
- **R-09** No secrets ever enter the repository. → ADR 0009
- **R-10** Claude Code never commits or pushes automatically; guardrails are
  enforced via `.claude/settings.json`. → ADR 0008, ADR 0013

## Architecture

- **R-11** User-facing packages and dotfiles live in Home Manager; nix-darwin
  holds only system-required configuration. → ADR 0006
- **R-12** Homebrew is limited to GUI casks and macOS-specific builds, fully
  declared, with activation cleanup enabled. → ADR 0005
- **R-13** `nixpkgs-unstable` is kept; `flake.lock` is frozen during the
  migration and updated only in dedicated commits after cutover. → ADR 0011

## Process

- **R-14** All repository artifacts and commit messages are in English.
  (Conversation with the owner may be in Japanese.)
- **R-15** ADRs use MADR-lite in `docs/adr/`, start as Proposed, and are
  promoted only by the owner. Requirements live in this file. → ADR 0007
- **R-16** Work happens on short-lived branches with Conventional Commits;
  `main` is protected. → ADR 0008
- **R-17** Everything automatable runs in GitHub Actions CI (build/eval,
  lint/format, secret scan, docs/commit hygiene) as required status checks;
  CI never activates a system. → ADR 0012
- **R-18** Post-cutover lock updates arrive as automated weekly PRs, merged
  manually. → ADR 0011, ADR 0012
- **R-19** Recurring procedures are captured as repository skills: `adr-new`
  and `migration-check`. → ADR 0013

## Completion

- **R-20** The migration is complete when cutover has been executed, the
  system has been stable for 2–4 weeks, and both legacy repositories are
  archived on GitHub. → ADR 0010
