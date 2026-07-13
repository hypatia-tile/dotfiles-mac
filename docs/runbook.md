# Runbook: verification, cutover, rollback

Skeleton — sections marked _TBD_ are completed before the cutover ADR can be
accepted (ADR 0003 makes this a hard precondition).

## 1. Pre-cutover verification (repeatable, non-destructive)

Run via the `migration-check` skill, or manually:

1. `nix flake check --no-update-lock-file`
2. `darwin-rebuild build --flake .#Kazukis-MacBook-Air`
   (or `nix build .#darwinConfigurations.Kazukis-MacBook-Air.system`)
3. `nix store diff-closures /run/current-system ./result` — review every
   line; during migration the lock is frozen, so any package-version change
   is unexpected and must be explained.
4. Collision check: enumerate files Home Manager will manage and compare
   with existing `$HOME` files (dot-link symlinks are expected collisions;
   `backupFileExtension = "hm-bak"` must be configured).
5. Secret scan over the working tree.

All five must pass, and the diff-closures review must be explicitly signed
off in the cutover ADR.

## 2. Cutover procedure (owner only)

_TBD in detail. Outline:_

1. Confirm the cutover ADR is Accepted and this runbook is complete.
2. Note the current generation: `darwin-rebuild --list-generations`.
3. Run `darwin-rebuild switch --flake .#Kazukis-MacBook-Air` manually.
4. Smoke test: new shell (zsh), tmux, Neovim, git identity, kitty/alacritty
   launch, aerospace/hammerspoon running, brew cleanup output reviewed.

## 3. Rollback

Two independent layers:

- **Generation rollback** (first resort):
  `darwin-rebuild rollback`, or
  `darwin-rebuild switch --switch-generation <N>` with the number recorded in
  step 2.2. This restores the previous system + HM generation.
- **Legacy restore** (last resort): the legacy repos remain intact and
  read-only. Re-running `~/github/dotfiles/bin/dot-link.sh` restores the
  symlink regime (warning: it force-removes targets first), and
  `darwin-rebuild switch` from `~/github/nix-darwin` restores the old system
  closure. Files HM backed up as `*.hm-bak` can be restored by renaming.

## 4. Post-cutover

1. Monitor for a 2–4 week stability window.
2. Enable the `update-flake-lock` workflow schedule (ADR 0011).
3. Archive `hypatia-tile/dotfiles` and `hypatia-tile/nix-darwin` on GitHub
   (ADR 0010).
4. First manual `nix flake update` in a dedicated PR.
