# Operations guide

Working knowledge for operating this repository after the cutover
(2026-07-14). The runbook covers cutover and rollback; this covers
day-to-day changes and the sharp edges discovered while migrating.

## 1. Changing configuration

Every change follows the same loop:

1. Branch off `main`, edit, and verify with the `migration-check` skill
   (build-only — nothing here ever switches).
2. PR with Conventional Commits; all CI checks are required; self-merge
   when green.
3. Apply manually: `sudo darwin-rebuild switch --flake .#Kazukis-MacBook-Air`.

The switch is always the owner's manual step. Nothing lands on the machine
until it is run, so merged-but-not-switched is a normal intermediate state.

### Changing the Neovim config

The nvim config is the pinned non-flake input `nvim-config`, placed
read-only from the store (ADR 0014). The proven loop:

1. Edit in the clone at `~/ghqrepo/github.com/hypatia-tile/nvim-config`.
   Verify the working tree there before landing it: `bin/check` runs a
   headless load (`Lazy! restore` to `lazy-lock.json`, then a clean
   startup — a refreshed `lazy-lock.json` belongs in the same commit);
   `bin/nvim-dev` opens the tree interactively under
   `NVIM_APPNAME=nvim-dev`, isolated from the live config. Note the limit:
   a clean `bin/check` proves startup, not lazy-loaded plugins. Commit,
   push, land on its `main`.
2. In this repo: `nix flake lock --update-input nvim-config` — as a
   **dedicated commit** (ADR 0011). Only the `nvim-config` node may change.
3. PR, merge, switch.
4. Post-switch check: launch `nvim` — no startup errors,
   `:echo stdpath('config')` resolves through `~/.config/nvim` to the new
   store path, `:Lazy` shows plugins clean against the shipped
   `lazy-lock.json`, and the behavior change that motivated the bump is
   actually observable.

Anything nvim must **write** cannot live in the config dir (it is a
read-only store path). Use `stdpath("data")` — e.g. the skkeleton user
dictionary is at `~/.local/share/nvim/skk/user-dict`, and the SKK L
dictionary is supplied by this flake at `~/.local/share/skk/SKK-JISYO.L`
(`pkgs.skkDictionaries.l` — the pinned nixpkgs has no `skk-dicts` attr).

### Updating inputs

`flake.lock` updates are manual, in dedicated commits (ADR 0011).
`nix flake update` (update everything) stays denied in the guardrails; use
`nix flake lock --update-input <name>` for targeted bumps. The weekly
`update-flake-lock` workflow is enabled only after the stability window.

## 2. Home Manager placement semantics (hard-won)

- **`backupFileExtension` only backs up regular files.** A directory — or a
  symlink to a directory — in the way of an HM target aborts the activation
  with "would be clobbered". Remove or move such targets manually before
  switching (this is what broke the first cutover attempt).
- **Directory-sourced `xdg.configFile."x"` makes `~/.config/x` a read-only
  store symlink.** If anything inside must stay writable, either link
  file-by-file with `recursive = true` (zsh does this: `HISTFILE` and
  `.zcompdump` live in ZDOTDIR) or keep the writable file outside the
  managed tree entirely (nvim user dictionary).
- **Nothing sources `hm-session-vars.sh` automatically.** HM's zsh
  integration is disabled because the zsh config is shipped as plain files,
  so `config/zsh/.zprofile` sources
  `/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh`
  explicitly. Removing that line silently drops `home.sessionVariables`
  and `home.sessionPath` (including `/opt/homebrew/bin`) from new shells —
  the legacy `.envrc` used to mask exactly this hole.

## 3. Nix on this machine (Determinate installer)

- `nix.enable = false`; nix-darwin does not own `/etc/nix/nix.conf` and any
  `nix.settings` set in the darwin layer is silently inert.
- The **effective** user configuration is the HM-managed
  `~/.config/nix/nix.conf` (from `config/nix/`). If that file is ever
  absent (e.g. mid-recovery), flakes are disabled; run one-offs with
  `NIX_CONFIG="experimental-features = nix-command flakes"` prefixed.

## 4. CI behavior

- **Docs-only PRs skip the macOS build job.** A `changes` job
  (dorny/paths-filter) gates it on `**/*.nix`, `flake.lock`, `config/**`,
  and `ci.yml`. The job is *skipped*, which still satisfies the required
  status check — do not convert this to workflow-level `paths-ignore`,
  which would leave the required check unreported and block merges.
  Pushes to `main` always build (cache warmth).
- **shellcheck ignores `config/`** — vendored payloads include zsh scripts,
  which shellcheck cannot parse (SC1071); they are data, not repo scripts.
- **Local markdownlint may be newer than CI's.** CI pins
  markdownlint-cli2-action@v19 (markdownlint-cli2 0.17.2); running the
  nixpkgs `markdownlint-cli2` locally can raise rules CI does not have
  (e.g. MD060) — check rule availability before "fixing" other files.
- Transient GitHub "Service Unavailable" failures in job *setup* are
  infrastructure, not code: rerun the failed job.

## 5. Known quirks and deferred cleanups

- `HISTFILE` is `~/.zsh_history`, not `$ZDOTDIR/history`: nix-darwin's
  `/etc/zshrc` runs after the user `.zprofile` and overrides it. This
  predates the migration; fix (if desired) by setting `HISTFILE` in
  `.zshrc` instead.
- `brew` cleanup on activation also autoremoves dependency orphans of
  whatever it uninstalls — expected, not a stop signal.
- The eval warning `nixfmt-rfc-style is now the same as pkgs.nixfmt` is a
  rename alias in the pinned nixpkgs; harmless until the package is renamed
  at the first post-window lock update.
- Deferred (candidates for their own PRs after the stability window):
  archive the legacy repos (ADR 0010), enable `update-flake-lock` + first
  manual update (ADR 0011), `system.defaults` phase (ADR 0002), `HISTFILE`
  fix, `programs.git` conversion, zsh-abbr from brew to nixpkgs.
