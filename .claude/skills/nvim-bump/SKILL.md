---
name: nvim-bump
description: Change the Neovim configuration and roll it into this flake — edit the nvim-config clone, land it on its main, bump the pinned input in a dedicated commit, and verify the build. Use when the owner wants to change anything under ~/.config/nvim.
---

# nvim-bump

The Neovim config is the pinned non-flake input `nvim-config`, placed
read-only from the store (ADR 0014). Changing it is a two-repository
operation.

## Steps

1. **Edit the clone** at `~/ghqrepo/github.com/hypatia-tile/nvim-config`
   (fetch/pull its `main` first; `ghq get hypatia-tile/nvim-config` if the
   clone is missing).
   - Anything nvim must **write** cannot live in the config dir — use
     `stdpath("data")` (e.g. the skkeleton user dictionary). Anything the
     flake should **provide** (dictionaries, binaries) belongs in
     dotfiles-mac, referenced by a stable `~/.local/share/...` path.
2. **Commit there** (Conventional Commits, English, only on explicit
   instruction) and ask the owner to push and land it on `main` — e.g.
   `! cd ~/ghqrepo/github.com/hypatia-tile/nvim-config && git push ...`.
   Wait until the commit is an ancestor of the remote `main`.
3. **Bump the pin** in dotfiles-mac on a feature branch:
   `nix flake lock --update-input nvim-config` — as a **dedicated commit**
   (ADR 0011). Verify the lock diff touches only the `nvim-config` node.
   Never `nix flake update`.
4. **Verify**: build the closure with `--no-update-lock-file` and check the
   changed file is present in the built generation's home-files under
   `.config/nvim/`. Run migration-check if anything beyond the pin moved.
5. Hand over to the `ship-pr` flow; after merge the owner applies with
   `sudo darwin-rebuild switch --flake .#Kazukis-MacBook-Air` and verifies
   the behavior change in nvim.

## Rules

- Never edit `~/.config/nvim` directly (read-only store path) and never
  edit the legacy submodule under `~/github/dotfiles`.
- The pin bump commit contains only `flake.lock`; related dotfiles-mac
  changes (e.g. a new `xdg.dataFile`) go in their own commit.
