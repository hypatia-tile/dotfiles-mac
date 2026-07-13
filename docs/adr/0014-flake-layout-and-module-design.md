# 0014. Flake layout and module design

- Status: Proposed
- Date: 2026-07-13

## Context

ADRs 0001–0013 are accepted and every inventory row has a verdict, so the
concrete flake structure can be fixed. Two facts discovered during design
constrain it: the machine uses the Determinate Nix installer (legacy config
sets `nix.enable = false`, so `nix.settings` is not authoritative), and an
unmanaged hand-written `~/.zshenv` is what bootstraps `ZDOTDIR` — the zsh
migration silently breaks without it.

## Decision

Adopt the layout and mapping specified in `docs/design/flake-design.md`:

- `hosts/` (hostname-keyed entries) + `modules/darwin` + `modules/home` +
  `config/` (plain-file dotfile payloads, vendored).
- Neovim config is consumed as the pinned non-flake input `nvim-config` and
  placed via `xdg.configFile`.
- `~/.zshenv` becomes HM-managed (inventory addendum A-14).
- User-level `~/.config/nix/nix.conf` stays the effective Nix configuration,
  HM-managed; `nix.enable = false` is kept.
- `texlive.combined.scheme-full` and `alejandra` are dropped from user
  packages (per inventory A-9 and the ADR 0012 formatter choice).
- `homebrew.onActivation.cleanup = "uninstall"`; casks declare the installed
  `emacs-app` name.
- Implementation proceeds in four build-only phases (skeleton → file
  placement → homebrew → cutover), one PR each, gated by `migration-check`.

## Consequences

- The first verification diff will be dominated by the intended texlive
  removal; any other unexplained delta is a defect signal.
- Editing Neovim config now means: push to `nvim-config`, bump the pinned
  input, rebuild — the accepted cost of full store management (ADR 0001).
- A second host later only adds a file under `hosts/`.
