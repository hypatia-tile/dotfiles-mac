---
name: config-change
description: The entry point for everyday changes to this machine's configuration — installing or removing a package, adding or editing a tool's config file, changing a Homebrew entry, a session variable, or a macOS default. Decides which layer the change belongs in, makes the edit, and names the check that proves it worked after the switch. Use whenever the owner wants to change what is installed or how a tool is configured.
---

# config-change

The everyday change loop: one entry point for "I want to add, remove, or
change something in my setup".

This skill owns exactly three things — **where the change goes, the edit
itself, and the check that proves it worked**. Verification, pull requests,
Neovim and lock updates each have their own skill; **do not restate their
steps** (ADR 0019). Invoke them.

## Steps

### 1. Check for prior context

Deferred work lives in GitHub Issues, not in the repository (ADR 0019), so a
change may already have a recorded reason for having been postponed.

```sh
gh issue list --state open
```

If an issue covers this change, read it before editing — it records what was
already tried and what blocked it — and reference it in the commit. Skip this
step only for a change that plainly cannot have a history (a brand-new tool).

### 2. Decide the layer

Use the table below. It is a **summary of ADRs 0005, 0006 and 0020 and has no
independent authority**: if a case is not covered, say so and ask rather than
extending the policy yourself.

### 3. Make the edit

Branch off `main` first. Keep one concern per branch.

### 4. Verify

Run the **`preflight`** skill. For a package or config change the closure diff
in its step 5 is the real evidence: the additions and removals must map to the
change under review and nothing else should move.

### 5. Ship

Hand over to the **`ship-pr`** skill. Its PR body needs the post-switch check
from the table below, stated concretely — the owner applies the change with
`sudo darwin-rebuild switch --flake .#Kazukis-MacBook-Air` after merge, and
that check is how they know it took.

## Decision table

| Change | Goes in | Authority |
|---|---|---|
| CLI tool, language, LSP, library | `modules/home/packages.nix` | ADR 0005, 0006 |
| GUI application | `homebrew.casks` in `modules/darwin/homebrew.nix` | ADR 0005 |
| Formula needing a macOS-specific source build | `homebrew.brews` | ADR 0005 |
| New tool's configuration file | `config/<tool>/` + `modules/home/files.nix` | ADR 0020 |
| Editing an existing tool's configuration | the file under `config/<tool>/` | ADR 0020 |
| Environment variable, `PATH` entry, launchd agent | `modules/home/base.nix` | ADR 0006 |
| macOS system default or keybinding | `modules/darwin/macos.nix` | ADR 0017 |
| Neovim configuration | the files under `config/nvim/` | ADR 0021 |
| `flake.lock` | **not here** — use `lock-review` | ADR 0011 |

Everything user-facing belongs to Home Manager; the darwin layer holds only
what the system requires (ADR 0006). `programs.*` is **not** the default form
for configuration — plain files are, and `programs.*` is reserved for cases
that need a Nix value or a Nix-side integration, such as `programs.direnv`
(ADR 0020).

### Traps that have already cost a PR

- **A directory-sourced `xdg.configFile` makes the target a read-only store
  symlink.** If the tool writes runtime state into its own config directory,
  either link file-by-file (`recursive = true`, as zsh does for `ZDOTDIR`) or
  link only the specific file (as `herdr/config.toml` does). Getting this
  wrong makes the tool fail at runtime, not at build.
- **A non-official Homebrew tap must be declared `trusted = true`** on the
  `homebrew.taps` entry, or activation refuses to load its formulae.
- **Whatever a `with-*` build option pulls in must be declared in `brews`
  too.** `onActivation.cleanup = "uninstall"` removes undeclared packages,
  including a formula's *optional* dependencies, leaving the program to abort
  on a missing dylib.
- **`system.defaults` writes replace the whole `AppleSymbolicHotKeys`
  dictionary** rather than merging, so `macos.nix` must stay the complete
  current set.

Their full stories are in `docs/operations.md` §2 and §5.

## Post-switch checks by kind

Name the applicable one in the PR body. "It built" is not one of these.

| Kind | Check |
|---|---|
| nixpkgs package added | `command -v <bin>` resolves under `/etc/profiles/per-user/…` or `~/.nix-profile`, and `<bin> --version` matches the version seen in the closure diff |
| nixpkgs package removed | `command -v <bin>` finds nothing |
| Homebrew cask | the app is in `/Applications` and launches |
| Homebrew formula | `brew list --versions <name>` |
| New config file | `readlink ~/.config/<tool>/…` points into `/nix/store`, **and** the tool is run once to confirm it actually reads the setting |
| Edited config | the specific behavior that changed, exercised directly |
| Session variable / `PATH` | open a **new** shell and `echo $VAR` — the value arrives via `hm-session-vars.sh`, sourced from `config/zsh/.zprofile` |
| macOS default / keybinding | `activateSettings -u`, then `defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys` matches `macos.nix`, then a behavior spot-check (`docs/operations.md` §1) |

## Rules

- **Never run `darwin-rebuild switch`, any activation script, or `sudo`.**
  Applying is the owner's manual step (ADR 0003, ADR 0015).
- **Never commit or push automatically.** Prepare the change and a proposed
  Conventional Commit message; commit only when told to, and never push.
- If the change turns out to need a new decision rather than an application of
  an existing one, stop and raise an ADR with `adr-new` instead of deciding it
  inside a configuration commit.
