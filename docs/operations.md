# Operations guide

Working knowledge for operating this repository: the semantics, the sharp
edges, and the things that are true about this machine rather than about any
one procedure. **Procedures themselves live in skills** (ADR 0019) — see
[`README.md`](README.md) for which skill covers what.

## 1. Changing configuration

Most changes need no switch at all. Payloads under `config/` are placed as
symlinks into this checkout (ADR 0021), so editing one is live as soon as the
program re-reads it — no build, no PR, no activation. What still needs a switch
is a change to the Nix layer, or to *which* links exist rather than what is in
them.

For those, the loop is:

1. Branch off `main`, edit, and verify with the `preflight` skill
   (build-only — nothing in that skill ever switches).
2. **Try it if you want to**: `sudo darwin-rebuild switch --flake .#Kazukis-MacBook-Air`
   from the branch is allowed, including from a dirty working tree (ADR 0022).
   Record the generation first — `docs/rollback.md` opens with why.
3. PR with Conventional Commits; all CI checks are required; self-merge
   when green.
4. Switch from `main` once it is merged.

Step 2 is optional and step 4 is not. The invariant is about where the machine
comes to rest, not about how it got there: **once a change is merged, the
machine runs `main`.** Iterating from a branch is expected; staying there is
drift. `bin/running-main-check.sh` answers it in about seven seconds by
building `main` and comparing with `/run/current-system`, and the `ship-pr`
skill names it as the post-merge step.

Step 4 is often already done by step 2, and the reason is worth knowing: **the
closure is content-addressed, not commit-addressed.** A squash-merge rewrites
the commit but not the tree, so building `main` afterwards yields the same
store path the branch did, and the check passes without a second switch. It
drifts only when the content genuinely differs — review edits on the PR, or
`main` having moved ahead meanwhile. Verified rather than assumed: the machine
switched from a branch, that branch was squash-merged, and the check reported
PASS against the identical path.

Nothing here changes who may switch. Claude never runs `darwin-rebuild switch`,
any activation script, or `sudo` (ADR 0018); this is about *when the owner*
may, which no ADR ever restricted — the earlier ordering was documentation
rather than a decision.

The `config-change` skill drives the loop and decides which layer a change
belongs in.

### Changing the Neovim config

The nvim config is a payload of this repository at `config/nvim`, and
`~/.config/nvim` is a symlink to it (ADR 0021). Edit it like any other payload:
the change is live when Neovim restarts, with no switch, no PR and no pin to
bump. It stopped being a two-repository operation when the config was imported
(ADR 0023, ADR 0024); the history before the import is in the archived
`hypatia-tile/nvim-config`.

What is a property of the setup rather than a step, and therefore lives here:
**anything nvim must *write* still belongs outside the config dir**, in
`stdpath("data")`. The directory is writable now, which is not an invitation to
use it — a config directory that accumulates runtime state stops being
reviewable, and the state would land in this repository's working tree. The
deliberate exception is `lazy-lock.json`, which a lockfile wants to be: written
by the editor *and* committed. The skkeleton user dictionary is at
`~/.local/share/nvim/skk/user-dict`, and the SKK L dictionary is supplied by
this flake at `~/.local/share/skk/SKK-JISYO.L` (`pkgs.skkDictionaries.l` — the
pinned nixpkgs has no `skk-dicts` attr).

Note the limit of the verification: a clean `config/nvim/bin/check` proves
startup, not lazy-loaded plugins.

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
- **`brew` cleanup's `Uninstalled N formulae` summary reports what it
  *evaluated*, not what it removed — and a failed uninstall is invisible.**
  Cleanup passes every candidate to a single `brew uninstall --formula
  --force` and then prints the count unconditionally; the exit status is
  discarded (`Kernel.system` in Homebrew's `bundle/subcommand/cleanup.rb`), so
  `brew bundle` still exits 0 and activation continues. When the line
  `Error: Refusing to uninstall … because they are required by emacs-plus@30`
  precedes it, that is `brew uninstall` protecting an installed formula's
  dependencies — the default behaviour that `--ignore-dependencies` switches
  off — and **the whole batch failed, so nothing was removed**, not just the
  named formulae. Never read the count as a fact. Verify on disk instead:
  `brew list --versions cairo gnutls librsvg jpeg` and `emacs --version`.
- **Non-official Homebrew taps must be declared `trusted = true`.** Homebrew
  6.0.0 enabled `HOMEBREW_REQUIRE_TAP_TRUST`, so activation aborts with
  "Refusing to load formula … from untrusted tap" for any non-official tap
  unless it is trusted. Set it on the `homebrew.taps` entry
  (`{ name = "…"; trusted = true; }`) — declarative and rebuild-safe — not via
  imperative `brew trust`. Tap-level trust covers the tap's formulae however
  the `brews` entry names them; formula-level `trusted` additionally requires
  a fully-qualified name. Declare tap formulae fully-qualified anyway — see
  the cleanup keep-set entry below.
- **The Brewfile `trusted:` marker only covers `brew bundle` (activation).**
  Direct maintenance commands (`brew reinstall`/`link`/`options` on the tap
  formula) still hit the trust guard and are refused. For a one-off, prefix
  with `HOMEBREW_NO_REQUIRE_TAP_TRUST=1` rather than running `brew trust`
  (which writes imperative state that diverges from the declarative setup),
  e.g. `HOMEBREW_NO_REQUIRE_TAP_TRUST=1 brew reinstall emacs-plus@30 --with-imagemagick`.
  The mechanism is a path split: Homebrew reads
  `${XDG_CONFIG_HOME}/homebrew/trust.json` when that variable is set and
  `~/.homebrew/trust.json` otherwise. Activation goes through `sudo`, which
  drops `XDG_CONFIG_HOME` and so writes and reads the latter; an interactive
  shell has `XDG_CONFIG_HOME` (`xdg.enable = true`) and reads the former,
  which does not exist. To inspect Homebrew exactly as activation sees it,
  prefix with `env -u XDG_CONFIG_HOME` — that reproduces the real view rather
  than bypassing the guard.
- **Declare a tap formula by its fully-qualified name, or cleanup marks its
  whole dependency tree for deletion.** `brew bundle cleanup` builds its
  keep-set by matching each Brewfile entry against the installed formulae's
  `full_name`, and skips an entry it cannot match — dependencies included. A
  bare `emacs-plus@30` never matches the installed
  `d12frosted/emacs-plus/emacs-plus@30`, so cleanup walked none of its
  dependencies and proposed removing all 40 of them. A core formula is
  unaffected because its `full_name` *is* its bare name, which is why
  `imagemagick` never showed the problem. Do not shorten the name in
  `modules/darwin/homebrew.nix`.

  This cost two incidents. At the 2026-07-14 cutover the formula was still
  being built, so no installed dependent existed to trigger the protection
  above and the batch succeeded — `emacs-plus@30` built while
  `cairo`/`gnutls`/`librsvg`/`jpeg`/… were removed, and the binary aborted on a
  missing dylib. The second time the protection was bypassed by hand with
  `brew uninstall --ignore-dependencies`, with the same result: that flag turns
  off the one thing standing between a stale removal list and a broken Emacs,
  so do not reach for it to force a cleanup through. Recovery either way is to
  put the dependencies back — `brew install <the missing formulae>` is enough
  and much cheaper than a source rebuild; `otool -L` on the binary names them.
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
