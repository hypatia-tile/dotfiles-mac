# Discovery inventory

Read-only scan of the current machine and the two legacy repositories,
performed 2026-07-13 on `Kazukis-MacBook-Air` (aarch64-darwin,
macOS 26.5.1). Per ADR 0002, **every row needs an owner verdict before
design/implementation starts.** Verdict vocabulary: `migrate` (bring into
dotfiles-mac), `exclude` (leave out permanently), `defer` (out of the initial
migration, revisit later).

Proposals are Claude's suggestions only. Secret-bearing paths were recorded
by filename and never read (ADR 0009).

**Verdict status: COMPLETE.** All rows were decided by the owner on
2026-07-13; the ADR 0002 gate is satisfied and design may proceed.

## A. Legacy `~/github/dotfiles` (symlink-managed via dot-link.sh)

| Item | Current owner / state | Proposal | Verdict |
|---|---|---|---|
| `.config/zsh/` (`.zshrc`, `.zshenv`, `.zprofile`, `modules/`, `abbr-definitions.zsh`, `complete/`, `functions/`) | dot-link symlink | migrate (HM `xdg.configFile`, keep ZDOTDIR layout) | migrate |
| `.config/git/` (`config`, `ignore`, `commit_template.txt`) | dot-link symlink; a stray `commit_template.txt.hm-bak` shows a past HM collision | migrate; delete the `.hm-bak` stray during cutover | migrate |
| `.config/tmux/tmux.conf` | dot-link symlink | migrate | migrate |
| `.config/kitty/kitty.conf` | dot-link symlink | migrate | migrate |
| `.config/alacritty/alacritty.toml` | dot-link symlink | migrate | migrate |
| `.config/aerospace/aerospace.toml` | dot-link symlink | migrate | migrate |
| `.config/nvim` | **git submodule → separate repo `hypatia-tile/nvim-config`**; `~/.config/nvim` symlinks into the dotfiles clone | migrate as a **pinned non-flake input** (`flake = false`) placed by HM — keeps the nvim repo independent while the lock hashes it. Alternative: vendor the files into dotfiles-mac | migrate (pinned non-flake input) |
| `.bash_profile`, `.bashrc` | dot-link symlink; contains Linux leftovers (`/snap/bin`, anaconda3) and a stale `ZDOTDIR=~/.zsh` | exclude — zsh is the shell; bash stays stock | exclude |
| `.latexmkrc` | dot-link symlink | defer — owner plans to move LaTeX to per-project flakes; TeX must **not** enter the system closure (build cost, CI concern). Revisit when the first LaTeX project flake exists | defer |
| `.envrc` (in `$HOME`) | dot-link symlink; rebuilds PATH (duplicates HM/nix-darwin `sessionPath`) and hardcodes a `/nix/store/...` JAVA_HOME | exclude the mechanism; carry `NVIM_FLOATING_MEMO_DIR` and a nixpkgs-referenced `JAVA_HOME` into HM `home.sessionVariables` | exclude (vars → HM) |
| `.hammerspoon/init.lua` | dot-link symlink; an HM launchd agent (`org.nix-community.home.hammerspoon`) already exists | migrate | migrate |
| `.emacs.d/` | dot-link symlink | **exclude** (Emacs out of scope, fixed decision) | excluded |
| repo-root `.gitignore`, `.gitmodules`, `bin/dot-link.sh`, `bin/*.txt`, `CLAUDE.md`, `README.md`, `LICENSE` | repo housekeeping | exclude — dot-link mechanism is retired by ADR 0001 | exclude |

## B. Legacy `~/github/nix-darwin` (flake)

| Item | Current owner / state | Proposal | Verdict |
|---|---|---|---|
| `flake.nix` + `nix/darwin/*` (configuration, fonts, nix, users, macos) | active system config | rewrite into the new flake (hostname-keyed, ADR 0004); format with nixfmt-rfc-style | migrate (rewrite) |
| `nix/home/*` (base, packages, programs) | active HM config; `programs.zsh/tmux/kitty/alacritty` deliberately disabled to avoid dot-link collisions | rewrite; re-enable file management via HM now that dot-link is retired | migrate (rewrite) |
| `flake.lock` | pins nixpkgs-unstable, nix-darwin, home-manager, neovim-nightly, rust-overlay | carry over as the frozen starting lock (ADR 0011) | migrate (frozen starting lock) |
| `nix/common.nix` (+ template) | user identity constants | migrate | migrate |
| `templates/` (cabal, stack, haskell, dev-shell) | dev project templates — not machine configuration | **exclude** from dotfiles-mac; consider a separate templates repo later | exclude |
| `docs/` incl. legacy ADRs 0001–0004 | historical documentation | exclude; remains readable in the archived repo (ADR 0007) | exclude |
| `migrate_brew.md`, `TODO.md` | old migration checklist | exclude — superseded by this inventory | exclude |

## C. Unmanaged `~/.config` entries (no repo owns these today)

| Item | Notes | Proposal | Verdict |
|---|---|---|---|
| `direnv/` | HM enables programs.direnv, but this config dir is unmanaged | migrate | migrate |
| `helix/` | helix installed via HM packages; config unmanaged | migrate | migrate |
| `lazygit/` | lazygit installed via HM packages | migrate | migrate |
| `nix/` | likely user nix.conf; overlaps nix-darwin `nix.settings` | migrate into nix-darwin settings, then drop the file | migrate (into nix.settings) |
| `fish/` | fish config; untouched since 2024-11, zsh is the primary shell | exclude | exclude |
| `skk/` | contains only the standard dictionary `SKK-JISYO.L` (4.5 MB distribution artifact), no personal config | exclude the file from the repo; provide the dictionary declaratively via nixpkgs `skk-dicts` and point the consumer (aquaskk/skkeleton — identify during design) at it | exclude (dict via nixpkgs) |
| `zsh-abbr/` | live `user-abbreviations` (2026-04-21) duplicates the repo-managed `abbr-definitions.zsh`; the plugin is hand-sourced from `~/.local/bin/zsh-abbr.zsh` despite the brew declaration | migrate: merge both abbreviation files into one HM-managed definition file and fix the plugin wiring to the declared install | migrate (merge & unify) |
| `mpv/` | media player config; last touched 2025-08 | exclude | exclude |
| `iterm2/` | kitty/alacritty are the declared terminals | exclude | exclude |
| `htop/` | auto-rewritten state file | exclude | exclude |
| `coc/` | old coc.nvim data; nvim config is now separate | exclude | exclude |
| `gh/` | **contains auth token — filenames only, never read** | exclude (ADR 0009) | excluded |
| `github-copilot/` | auth state | exclude (ADR 0009) | excluded |
| `cabal/`, `ghc/` | toolchain state | exclude | exclude |
| `configstore/`, `powershell/`, `wireshark/` | app state / rarely used | exclude | exclude |

## D. Homebrew: declared vs. installed

Declared in legacy `macos.nix` — brews: `llvm`, `make`, `cmake`,
`olets/tap/zsh-abbr`; casks: `hammerspoon`, `nikitabobko/tap/aerospace`,
`emacs`.

| Item | State | Proposal | Verdict |
|---|---|---|---|
| brews `llvm`, `make`, `cmake`, `zsh-abbr` | declared + installed | keep declared (llvm justifies the brew exception lane, ADR 0005) | migrate (keep declared) |
| leaves `libidn2`, `nettle`, `p11-kit` | **undeclared** orphaned dependencies | remove — `onActivation.cleanup` will purge them; confirm nothing needs them | exclude (cleanup removes) |
| cask `aquaskk` | **undeclared — will be uninstalled by cleanup at first activation** | declare it (Japanese input method presumably in daily use) | exclude — owner confirmed it is unused; cleanup removal accepted |
| cask `emacs-app` | installed name differs from declared `emacs` | declare the actually-installed `emacs-app` (Emacs *config* stays out of scope; the cask must still be declared to survive cleanup) | migrate (declare `emacs-app`) |
| masApps | none declared, none required so far | keep empty | keep empty |

## E. `~/Library/LaunchAgents`

| Item | Proposal | Verdict |
|---|---|---|
| `org.nix-community.home.hammerspoon.plist` | HM-managed; carries over automatically | migrate (follows HM config) |
| Google Updater/Keystone ×3, Zoom ×2, CleanMyMac, Steam | app-managed; exclude | exclude |

## F. macOS defaults

Out of initial scope (ADR 0002). Current values recorded in
[macos-defaults-snapshot.md](macos-defaults-snapshot.md) for the later
`system.defaults` phase.
