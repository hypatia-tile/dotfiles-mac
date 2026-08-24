# Operations guide

Working knowledge for operating this repository: the semantics, the sharp
edges, and the things that are true about this machine rather than about any
one procedure. **Procedures themselves live in skills** (ADR 0019) — see
[`README.md`](README.md) for which skill covers what.

## 1. Changing configuration

Every change follows the same loop:

1. Branch off `main`, edit, and verify with the `preflight` skill
   (build-only — nothing here ever switches).
2. PR with Conventional Commits; all CI checks are required; self-merge
   when green.
3. Apply manually: `sudo darwin-rebuild switch --flake .#Kazukis-MacBook-Air`.

The `config-change` skill drives that loop and decides which layer a change
belongs in. The switch is always the owner's manual step: nothing lands on the
machine until it is run, so merged-but-not-switched is a normal intermediate
state.

### Changing the Neovim config

The nvim config is the pinned non-flake input `nvim-config`, placed read-only
from the store (ADR 0014), so changing it is a two-repository operation. The
procedure is the `nvim-bump` skill, verified by `bin/nvim-bump-check.sh`.

What is a property of the setup rather than a step, and therefore lives here:
**anything nvim must *write* cannot live in the config dir**, because it is a
read-only store path. Use `stdpath("data")` — the skkeleton user dictionary is
at `~/.local/share/nvim/skk/user-dict`, and the SKK L dictionary is supplied
by this flake at `~/.local/share/skk/SKK-JISYO.L` (`pkgs.skkDictionaries.l` —
the pinned nixpkgs has no `skk-dicts` attr).

Note the limit of the verification: a clean `bin/check` in the nvim-config
clone proves startup, not lazy-loaded plugins.

### macOS keybindings

Keybindings (ADR 0017) are build-only verifiable for *content*, never for
runtime behavior, so they are always confirmed by hand after the switch; the
`config-change` skill carries the steps.

**Drift caveat:** the `system.defaults` write **replaces the whole
`AppleSymbolicHotKeys` dictionary** rather than merging into it. Changing any
shortcut in System Settings is therefore reverted on the next switch — edit
`modules/darwin/macos.nix` instead, and keep it the complete current set.

### Updating inputs

`flake.lock` updates are manual, in dedicated commits (ADR 0011).
`nix flake update` (update everything) stays denied in the guardrails; use
`nix flake lock --update-input <name>` for targeted bumps. The weekly
`update-flake-lock` workflow is enabled (ADR 0018) and opens PRs on schedule;
merging is always manual, and reviewing one is the `lock-review` skill.

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

## 5. Known quirks

Knowledge that does not expire. Work that is merely *not done yet* is not
here — it is filed as a GitHub issue (`gh issue list`, ADR 0019).

- `HISTFILE` is `~/.zsh_history`, not `$ZDOTDIR/history`: nix-darwin's
  `/etc/zshrc` runs after the user `.zprofile` and overrides it. This
  predates the migration.
- `brew` cleanup on activation also autoremoves dependency orphans of
  whatever it uninstalls — expected, not a stop signal.
- **`brew` cleanup's `Uninstalled N formulae` summary is cosmetic when it is
  preceded by `Error: Refusing to uninstall … because they are required by
  emacs-plus@30`.** The "Refusing" line means cleanup tried to remove
  emacs-plus@30's dependency tree and Homebrew *protected* it (tap trust
  working — the healthy path, the opposite of the first-activation dep loss
  below); the formulae it names stay installed. The trailing count reflects
  what cleanup *evaluated*, not what was removed, so it can overlap the
  protected set and look alarming. Verify on-disk reality instead of trusting
  the count: e.g. `brew list --versions cairo gnutls librsvg jpeg` and
  `emacs --version`. Only treat it as breakage if a dep is actually gone or
  Emacs aborts on a missing dylib.
- **Non-official Homebrew taps must be declared `trusted = true`.** Homebrew
  6.0.0 enabled `HOMEBREW_REQUIRE_TAP_TRUST`, so activation aborts with
  "Refusing to load formula … from untrusted tap" for any non-official tap
  unless it is trusted. Set it on the `homebrew.taps` entry
  (`{ name = "…"; trusted = true; }`) — declarative and rebuild-safe — not via
  imperative `brew trust`. Formula-level `trusted` only takes effect for
  fully-qualified names, so for a bare name like `emacs-plus@30` the trust
  must come from the containing `d12frosted/emacs-plus` tap.
- **The Brewfile `trusted:` marker only covers `brew bundle` (activation).**
  Direct maintenance commands (`brew reinstall`/`link`/`options` on the tap
  formula) still hit the trust guard and are refused. For a one-off, prefix
  with `HOMEBREW_NO_REQUIRE_TAP_TRUST=1` rather than running `brew trust`
  (which writes imperative state that diverges from the declarative setup),
  e.g. `HOMEBREW_NO_REQUIRE_TAP_TRUST=1 brew reinstall emacs-plus@30 --with-imagemagick`.
- **First activation on a fresh machine can strip an untrusted-tap formula's
  dependencies.** If cleanup runs before the tap's trust is established, it
  cannot resolve the untrusted formula's dependency tree and uninstalls *all*
  of it — the formula builds, but the binary then aborts on missing dylibs
  (we hit this: `emacs-plus@30` built while `cairo`/`gnutls`/`librsvg`/`jpeg`/…
  were removed). Recover by reinstalling once so the deps come back and relink:
  `HOMEBREW_NO_REQUIRE_TAP_TRUST=1 brew reinstall emacs-plus@30 --with-imagemagick`;
  a subsequent cleanup keeps them (verified with `brew bundle cleanup --file=…`
  dry-run: nothing removed).
- **emacs-plus builds `Emacs.app` in its Cellar, not `/Applications`.** As a
  formula (not a cask) it does not install a GUI app the way `emacs-app` did,
  and a symlink into `/Applications` integrates poorly with Spotlight /
  Launchpad / Dock. Copy the apps in with `bin/link-emacs-plus-app.sh` (it
  `cp -R`s `Emacs.app` and `Emacs Client.app` from
  `$(brew --prefix)/opt/emacs-plus@30` over any stale entry). The copy is
  version-pinned, so **re-run the script after every
  `brew reinstall emacs-plus@30`**.
- **Check a formula's real option set before passing `args`.** `brew install`
  aborts on the first invalid option (e.g. `emacs-plus@30` has no
  `--with-native-comp` — it always builds `--with-native-compilation=aot` —
  and no `--with-poll`). Read the tapped `.rb` to see the valid options:
  `$(brew --repository)/Library/Taps/<user>/homebrew-<repo>/Formula/<name>.rb`.
  For `emacs-plus@30` the only extra option we pass is `with-imagemagick`.
- **A formula's *optional* dependencies must be declared, or cleanup removes
  them.** `emacs-plus@30 --with-imagemagick` links `libMagickWand`/`Core` and
  `libtiff.6.dylib`, but `imagemagick` is only an optional dependency of the
  formula, so `onActivation.cleanup = "uninstall"` uninstalled it (and its
  `libtiff`) as "undeclared" — leaving Emacs to abort at launch with
  `Library not loaded: …/libtiff.6.dylib`. Add such libraries to `brews`
  (declaring `imagemagick` keeps `libtiff` too, as its dependency). General
  rule: whatever a `with-*` option pulls in must be declared alongside the
  formula. Symptom to recognize: the build/link succeeds but the program
  aborts on a missing dylib under `/opt/homebrew/opt/<lib>`.
- The eval warning `nixfmt-rfc-style is now the same as pkgs.nixfmt` is a
  rename alias in the pinned nixpkgs; harmless until the attribute is actually
  renamed upstream, at which point `modules/home/packages.nix` needs the new
  name. Watch for it when reviewing a lock update (`lock-review`).
