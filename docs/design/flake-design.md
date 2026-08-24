# Flake design

> **Historical record — the 2026-07 migration.** This is the design ADR 0014
> adopted, and its §6 implementation phases are all merged. It is **not
> maintained**, and parts of it are knowingly wrong now:
>
> - **§5's Homebrew module no longer matches
>   `modules/darwin/homebrew.nix`.** It passes `with-native-comp` and
>   `with-poll`, which do not exist on `emacs-plus@30` and abort the install
>   (fixed in #22), and omits `imagemagick` (#24), `tailscale-app` (#33) and
>   the tap `trusted` flag (#21). Read the module, not this block.
> - **§3's note about converting git to `programs.git` was withdrawn** by
>   ADR 0020, which makes plain files the default form.
>
> For the current layout start at [`README.md`](README.md). Kept in place
> because ADR 0014 delegates its content to this file by path (ADR 0019).

Design for the dotfiles-mac flake, derived from the accepted ADRs and the
completed inventory verdicts. Implementation follows the phases in §6; each
phase is one PR verified by `migration-check`.

## 1. Inputs

| Input | Source | Notes |
|---|---|---|
| `nixpkgs` | `github:NixOS/nixpkgs/nixpkgs-unstable` | ADR 0011 |
| `nix-darwin` | `github:nix-darwin/nix-darwin/master` | follows nixpkgs |
| `home-manager` | `github:nix-community/home-manager` | follows nixpkgs; darwin module |
| `neovim-nightly-overlay` | `github:nix-community/neovim-nightly-overlay` | carried over |
| `rust-overlay` | `github:oxalica/rust-overlay` | carried over |
| `nvim-config` | `github:hypatia-tile/nvim-config`, **`flake = false`** | inventory A-7: pinned non-flake input, placed by HM |

`flake.lock` starts from the legacy repository's lock (frozen, ADR 0011);
the only new entry is `nvim-config`.

## 2. Layout

```text
flake.nix
flake.lock
hosts/
  kazukis-macbook-air.nix     # host entry; attr name "Kazukis-MacBook-Air"
modules/
  common.nix                  # identity constants (from legacy nix/common.nix)
  darwin/                     # system layer — ADR 0006: system-required only
    default.nix               # aggregator
    nix.nix                   # nix.enable = false (Determinate), nixpkgs config
    fonts.nix                 # nerd-fonts.jetbrains-mono
    homebrew.nix              # split out of legacy macos.nix; cleanup enabled
    macos.nix                 # empty placeholder for the later defaults phase
    users.nix
  home/                       # user layer — everything user-facing
    default.nix
    base.nix                  # identity, sessionPath/Variables, launchd agents
    packages.nix
    programs.nix              # programs.direnv etc.
    files.nix                 # all xdg.configFile / home.file placements
config/                       # vendored dotfile payloads (plain files, no Nix)
  zshenv                      # → ~/.zshenv (ZDOTDIR bootstrap; see §4 note 1)
  zsh/  git/  tmux/  kitty/  alacritty/  aerospace/  hammerspoon/
  helix/  lazygit/  direnv/
```

Rationale: `hosts/` + `modules/` keeps a second machine additive (ADR 0004);
`config/` separates payloads from Nix logic so file diffs stay readable;
`darwinConfigurations` is built by iterating `hosts/`, which keeps CI
host-agnostic (ADR 0012).

## 3. Source → target mapping (migrate verdicts)

| Inventory item | Target |
|---|---|
| `.config/zsh/` | `config/zsh/` → `xdg.configFile."zsh"` (ZDOTDIR layout kept) |
| `~/.zshenv` (new finding, §4 note 1) | `config/zshenv` → `home.file.".zshenv"` |
| `.config/git/` | `config/git/` → `xdg.configFile."git"` (plain files initially; `programs.git` conversion is a possible later cleanup) |
| tmux / kitty / alacritty / aerospace | `config/<name>/` → `xdg.configFile` |
| nvim | `xdg.configFile."nvim".source = inputs.nvim-config` (read-only store path) |
| `.hammerspoon/init.lua` | `config/hammerspoon/` → `home.file.".hammerspoon"`; keep the existing HM launchd agent |
| helix / lazygit / direnv configs | snapshot current `~/.config/<name>` into `config/<name>/` |
| zsh-abbr | merge `~/.config/zsh-abbr/user-abbreviations` into `config/zsh/abbr-definitions.zsh`; `modules/abbr.zsh` sources the brew-installed plugin (`/opt/homebrew/share/zsh-abbr/zsh-abbr.zsh`) instead of `~/.local/bin` |
| `.envrc` env vars | `home.sessionVariables`: `NVIM_FLOATING_MEMO_DIR`; `JAVA_HOME` derived from `pkgs.jdk21_headless` (replaces the hardcoded store path) |
| user `nix.conf` | `xdg.configFile."nix/nix.conf"` managed by HM (see §4 note 2) |
| SKK dictionary | dropped from `~/.config/skk`; if a consumer resurfaces, provide via `pkgs.skk-dicts` (inventory C-6) |
| darwin modules / HM modules / common.nix | rewritten per §2, formatted with nixfmt-rfc-style |
| homebrew declarations | `modules/darwin/homebrew.nix` — see §5 |

## 4. Design notes

1. **`~/.zshenv` was unmanaged.** A hand-written 35-byte file
   (`export ZDOTDIR="$HOME/.config/zsh"`) is the linchpin that makes the
   whole zsh setup load. It was missed by discovery (added to the inventory
   as row A-14) and becomes HM-managed.
2. **Determinate Nix installer.** The legacy config sets `nix.enable =
   false`, so nix-darwin does not own `/etc/nix/nix.conf` and `nix.settings`
   would be silently ignored. The inventory C-4 verdict ("merge user
   nix.conf into nix.settings") is therefore implemented as an HM-managed
   `~/.config/nix/nix.conf` instead, keeping `nix.enable = false`.
3. **texlive leaves the closure.** Legacy `packages.nix` contains
   `texlive.combined.scheme-full`, which contradicts the A-9 verdict (LaTeX
   deferred to per-project flakes; TeX must not enter the system closure).
   It is dropped; expect a large negative closure diff at verification.
4. **Formatter swap.** `alejandra` is removed from user packages;
   `nixfmt-rfc-style` takes its place (ADR 0012).
5. **HM safety settings carried over**: `backupFileExtension = "hm-bak"`,
   `useGlobalPkgs`, `useUserPackages`.
6. **`EDITOR = "nvim"`** and the neovim-nightly/rust overlays carry over
   unchanged.

## 5. Homebrew module

```nix
homebrew = {
  enable = true;
  onActivation.cleanup = "uninstall";  # declared-only; "zap" deferred
  taps = [ "d12frosted/emacs-plus" ];
  brews = [
    "llvm" "make" "cmake" "olets/tap/zsh-abbr"
    { name = "emacs-plus@30";
      args = [ "with-native-comp" "with-imagemagick" "with-poll" ];
      link = true; }
  ];
  casks = [ "hammerspoon" "nikitabobko/tap/aerospace" ];
  masApps = { };
};
```

Emacs is provided by the `d12frosted/emacs-plus` tap's `emacs-plus@30`
formula (built from source), not the `emacs-app` cask.

Expected removals at first activation (all confirmed in inventory):
`aquaskk` (unused) and orphaned formulas `libidn2`/`nettle`/`p11-kit`.

## 6. Implementation phases

Each phase is one PR; `migration-check` must pass before merge; the system
is never switched (ADR 0003).

1. **Skeleton**: flake.nix, carried lock + `nvim-config` pin, `hosts/`,
   darwin layer, HM base + packages (no file management yet). Goal: closure
   builds and `diff-closures` vs the live system shows only the intended
   deltas (texlive/alejandra out, nothing else unexplained).
2. **File placement**: vendor `config/`, wire `files.nix` (zsh, zshenv, git,
   tmux, kitty, alacritty, aerospace, hammerspoon, helix, lazygit, direnv,
   nvim input, nix.conf), merge zsh-abbr definitions, fix abbr plugin
   sourcing. Goal: collision check lists exactly the dot-link symlinks.
3. **Homebrew**: `homebrew.nix` with cleanup as in §5.
4. **Cutover**: complete `docs/runbook.md` §2, raise the cutover ADR
   (Proposed → owner accepts), owner runs `darwin-rebuild switch`, executes
   the runbook smoke tests, then removes stray `*.hm-bak` files.

Post-cutover (out of migration scope): stability window → archive legacy
repos (ADR 0010), enable the lock-update schedule (ADR 0011), then the
`system.defaults` phase (ADR 0002) and optional cleanups (e.g.
`programs.git` conversion, moving `zsh-abbr` from brew to nixpkgs).
