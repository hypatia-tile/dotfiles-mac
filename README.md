# dotfiles-mac

Declarative macOS configuration for `Kazukis-MacBook-Air`: one Nix flake
combining **nix-darwin** for the system layer and **Home Manager** (as a
nix-darwin module) for everything user-facing.

It has been the single source of truth for this machine since the 2026-07-14
cutover, when it replaced two earlier repositories — a symlink-based
[dotfiles](https://github.com/hypatia-tile/dotfiles) and a separate
[nix-darwin](https://github.com/hypatia-tile/nix-darwin) flake. Both are now
archived and kept only as rollback material.

## Layout

```text
flake.nix              # inputs; builds one darwinConfiguration per hosts/*.nix
hosts/                 # one file per machine
modules/
  common.nix           # identity constants
  darwin/              # system layer — only what the system requires
  home/                # user layer — packages, files, session environment
config/                # dotfile payloads, in each tool's native format
docs/                  # see docs/README.md for the index
.claude/skills/        # the procedures for changing any of the above
```

Two rules shape it: everything user-facing lives in Home Manager and the
darwin layer holds only system-required settings (ADR 0006), and Homebrew is
limited to GUI casks and macOS-specific source builds (ADR 0005).
Configuration is vendored as plain files rather than re-expressed as Home
Manager `programs.*` options (ADR 0020), so `config/` stays readable as the
tools' own config.

## Applying it

```sh
sudo darwin-rebuild switch --flake .#Kazukis-MacBook-Air
```

This is always run by hand. Merging a change does not apply it —
merged-but-not-switched is a normal intermediate state.

## Changing it

Start at [`docs/README.md`](docs/README.md). Procedures live in
`.claude/skills/`, one per kind of change; the everyday entry point is
`config-change`, and `preflight` mirrors the CI gates locally before anything
is pushed. Decisions are recorded as ADRs in [`docs/adr/`](docs/adr/).

If something goes wrong after a switch, see
[`docs/rollback.md`](docs/rollback.md).

## Safety model

The live system is never touched by automation. CI and assistant tooling are
restricted to `nix flake check` and `nix build`; `darwin-rebuild switch` is
the owner's manual step alone, and `.claude/settings.json` denies it
mechanically. `flake.lock` moves only in dedicated commits, from the weekly
update workflow or the owner. No secrets ever enter this repository.
