# 0037. Move package management into nix-packages

- Status: Proposed
- Date: 2026-10-28

## Context

This flake declares both what is installed and how each tool is configured:
`modules/home/packages.nix`, `modules/darwin/homebrew.nix` and
`modules/darwin/fonts.nix` beside the payloads under `config/`, with one
`flake.lock` pinning `nixpkgs`, the overlays, nix-darwin and Home Manager
together. As the setup grows, that makes it hard to say which part is
responsible for what. "What is installed, and at which version" — the weekly
lock PRs, `lock-review`, vulnerability tracking — is one responsibility; how a
tool is configured is another. The problem and the decisions below were
settled with the owner in #310. The first issue of the new repository is
hypatia-tile/nix-packages#1.

ADR 0001 merged a split pair of repositories into this one flake. That split
was by mechanism: symlinked dotfiles beside a Home Manager flake that disabled
`programs.*` to avoid colliding with them. The split here is by
responsibility, with one placer (Home Manager, ADR 0034) and still one flake
that is built and switched.

ADR 0034 already has the reverse shape: `hypatia-tile/nixos-config` imports
this repository's shared payload module, taking configuration from outside.
Here, this repository takes packages from outside.

## Decision

**Package management moves to `hypatia-tile/nix-packages`, a public flake.
This repository keeps the configuration of tools and stays the only flake
that is built and switched.** This supersedes ADR 0001 in so far as it puts
package declarations in this flake; its single entry point stands.

- **What moves:** Nix packages, Homebrew casks and brews, and fonts. **What
  stays:** `programs.*` (ADR 0020), macOS defaults (ADR 0017), the payloads
  (ADR 0034), and this repository's devShells, which are its own gates rather
  than packages for the host. ADR 0005's Homebrew policy and ADR 0006's
  boundary still decide where a package goes; they now apply inside
  `nix-packages`.
- **Versions are package management.** `nix-packages` owns `nixpkgs` and the
  overlays, `emacs-flake` keeping its deliberate lack of `follows`
  (ADR 0031). This repository follows its `nixpkgs`, and so do nix-darwin and
  Home Manager. This repository decides when to take a new package set by
  moving its `nix-packages` input; ADR 0011 applies to that input as to any
  other, and to `nix-packages`' own lock.
- **One host now, two modules from the start:** a shared module and a
  macOS-only one, by whether the tool is macOS-specific, so that
  `nixos-config` can import the shared module later.
- **No interface.** The modules are imported as they are. An abstract,
  type-class-style interface for absorbing OS differences was considered and
  not chosen; #310 records why. The facts config here relies on about
  packages there (zsh-abbr's profile path, `osv-scanner` on `PATH`) are a
  known gap, left as they are until one breaks or a second host arrives.
- **A tool that needs both sides** is added package first, then config, and
  removed config first, then package, so neither repository is ever broken in
  between.
- **Tracking moves with the versions:** the weekly lock workflow,
  `lock-review`, the deferrals and the `vulnerability` issues. `vulns` stays
  here as a payload and reads deferrals from the `nix-packages` checkout.
- **`nix-packages` keeps a reduced copy of this repository's rules** — its own
  `AGENTS.md` with the same hard rules, `agent-guard`, the gates that apply,
  and its own ADRs.
- **Verification at two levels.** `nix-packages`' CI evaluates and builds its
  modules on its own; `preflight` here builds the host against a local
  checkout before a `nix-packages` change merges.
- **The cutover changes nothing on the machine.** The system after it builds
  to the same store path as before, and the Homebrew lists evaluate to the
  same values. A version change during the cutover is a reason to stop.

The stages and their order are in #310.

## Consequences

- This repository answers one question, how tools are configured. Which
  version is installed, and whether it is vulnerable, is answered in
  `nix-packages`.
- Adopting or dropping a tool becomes two PRs in two repositories, in a fixed
  order. That is the price of the split, and it works against #81's choice as
  the unit of removal, which spans both.
- There are two lock files and two weekly reviews. This repository's review
  shrinks to nix-darwin, Home Manager and the `nix-packages` input.
- The rules exist twice, so the copies can drift. A drift found is an inbox
  entry, not a reason to make `nix-packages` depend on this repository.
- `host-environment` (user-scope) and `config-change` must learn that
  installed packages belong to `nix-packages`; they change with the cutover,
  because a user-scope skill is live in every session as soon as it is edited.
- The cross-repository assumptions are undeclared. A package change there can
  break config here with no check on either side until the override build in
  `preflight` exists.
