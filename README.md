# dotfiles-mac

Declarative macOS configuration: one Nix flake combining nix-darwin (system
layer) and Home Manager (user layer). This repository is the consolidation
target for two legacy repositories
([dotfiles](https://github.com/hypatia-tile/dotfiles),
[nix-darwin](https://github.com/hypatia-tile/nix-darwin)), which stay
read-only during the migration and will be archived afterwards.

## Status

**Migration in preparation.** No flake exists here yet; the current phase is
governance and discovery. See:

- [`docs/requirements.md`](docs/requirements.md) — what this migration must
  achieve
- [`docs/adr/`](docs/adr/) — the decisions (all currently `Proposed`)
- [`docs/discovery/inventory.md`](docs/discovery/inventory.md) — per-item
  migration verdicts
- [`docs/runbook.md`](docs/runbook.md) — cutover and rollback procedures

## Safety model

The live system is never touched by automation: CI and assistant tooling are
restricted to `nix flake check` / `nix build`; `darwin-rebuild switch` is
executed only manually by the owner after an accepted cutover ADR. Secrets
never enter this repository.
