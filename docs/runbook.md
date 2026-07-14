# Runbook: verification, cutover, rollback

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

Every step below is run manually by the owner; nothing here is automated
(ADR 0003).

### 2.1 Preconditions

1. The cutover ADR (0015) is Accepted and its diff-closures sign-off is
   recorded.
2. Section 1 of this runbook passed on the exact commit being switched to,
   on `main`, with `flake.lock` unchanged.
3. A current Time Machine (or equivalent) backup exists.

### 2.2 Pre-switch snapshot

Record the state needed for rollback and for judging the switch:

1. `darwin-rebuild --list-generations | tail -5` — note the current
   generation number.
2. `brew list --cask && brew leaves` — expected cleanup removals are the
   cask `aquaskk` and formulas `libidn2`, `nettle`, `p11-kit`, plus
   whatever dependency orphans `brew autoremove` takes with them
   (observed: `gettext`, `gmp`, `libtasn1`, `libunistring`); any removal
   that is not one of these or a dependency of one is a stop signal.
3. `ls -l ~/.zshenv ~/.hammerspoon ~/.config/{zsh,git,tmux,kitty,alacritty,aerospace,nvim,nix,lazygit}`
   — the known collision set: eight dot-link symlinks, the hand-written
   `~/.zshenv`, and two real directories.

### 2.3 Prepare collision targets

Home Manager's `backupFileExtension` only backs up **regular files**.
Directories — and symlinks to directories, which is what the dot-link
links are — abort the activation with "would be clobbered" instead
(observed at the 2026-07-14 cutover). Worse, a directory target linked
file-by-file (zsh) is inspected *through* an existing symlink, so the
`*.hm-bak` renames would land inside the read-only legacy repository.

Therefore remove every dot-link symlink first (they are plain symlinks;
the real files stay in the legacy repository, and `dot-link.sh` can
recreate them for rollback):

```sh
rm ~/.hammerspoon ~/.config/zsh ~/.config/git ~/.config/tmux \
   ~/.config/kitty ~/.config/alacritty ~/.config/aerospace ~/.config/nvim
```

Then move the two real directories aside:

```sh
mv ~/.config/nix ~/.config/nix.pre-cutover
mv ~/.config/lazygit ~/.config/lazygit.pre-cutover
```

Their contents are already vendored in `config/`; the `.pre-cutover` copies
are deleted in step 2.6.

Note: moving `~/.config/nix` disables flakes until Home Manager places the
managed `nix.conf`, so run the switch with the feature flags supplied
explicitly (2.4).

### 2.4 Switch

```sh
sudo NIX_CONFIG="experimental-features = nix-command flakes" \
  darwin-rebuild switch --flake .#Kazukis-MacBook-Air
```

(The `NIX_CONFIG` prefix is only needed while the user `nix.conf` from 2.3
is moved aside; subsequent rebuilds don't need it.)

Review the activation output in full, in particular the Homebrew cleanup
lines (expected removals per 2.2) and every `hm-bak` backup message.

### 2.5 Smoke test

| Area | Check |
| --- | --- |
| zsh | open a **new** terminal: prompt renders, `echo $ZDOTDIR` → `~/.config/zsh`, history writes (`fc -l` after a command), abbreviations expand on space. Note: `HISTFILE` is `~/.zsh_history`, not `$ZDOTDIR/history` — nix-darwin's `/etc/zshrc` overrides the user `.zprofile`; this predates the migration |
| PATH/env | `echo $EDITOR` → `nvim`; `echo $JAVA_HOME` → a `/nix/store` path; `echo $NVIM_FLOATING_MEMO_DIR` |
| git | `git config user.name` → `shinokun`; `git commit` shows the template; delta renders a diff |
| nvim | launch; config comes from the store (`:echo stdpath('config')` resolves through `~/.config/nvim`) |
| tmux | prefix `C-q` works, pane navigation with `C-hjkl` |
| terminals | kitty and alacritty launch with fonts/colors |
| WM | aerospace responds to `cmd-hjkl`; hammerspoon shows "config loaded" alert (or `cmd-alt-R`) |
| brew | `brew list --cask` no longer shows `aquaskk`; `emacs-app` still installed |
| nix | `nix flake metadata ~/ghqrepo/github.com/hypatia-tile/dotfiles-mac` works (flakes still enabled via the HM-managed nix.conf) |

Any failed check → decide immediately: fix forward only for trivial,
config-content issues; otherwise roll back (section 3) and reassess.

### 2.6 Post-switch cleanup (only after 2.5 fully passes)

1. Inventory the backups: `find ~ -maxdepth 3 -name '*.hm-bak' 2>/dev/null`.
   Each one must correspond to a known collision from 2.2; investigate any
   surprise before deleting.
2. Delete the `*.hm-bak` files and the two `*.pre-cutover` directories.
3. `rm ~/.envrc` — the dot-link symlink to the retired direnv mechanism
   (inventory A-13). It is not a Home Manager target, so activation leaves
   it behind, and while present direnv keeps overriding `JAVA_HOME` with
   the stale hardcoded store path (observed at the 2026-07-14 cutover).
4. Do **not** touch the legacy repositories — they stay intact for the
   stability window (section 4).

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
