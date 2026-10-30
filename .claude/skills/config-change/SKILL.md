---
name: config-change
description: The entry point for everyday changes to this machine's configuration — installing or removing a package, adding or editing a tool's config file, changing a Homebrew entry, a session variable, or a macOS default. Decides which layer the change belongs in (what is installed now lives in hypatia-tile/nix-packages), makes the edit, and names the check that proves it worked after the switch. Use whenever the owner wants to change what is installed or how a tool is configured.
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

Use the table below. It is a **summary of ADRs 0005, 0006, 0020 and 0037 and has no
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
| CLI tool, language, LSP, library | **not here** — `modules/home/shared.nix` in nix-packages, or `modules/home/darwin.nix` there when the tool is macOS-specific; see below | ADR 0037, 0005, 0006 |
| GUI application | **not here** — `homebrew.casks` in nix-packages' `modules/darwin/homebrew.nix` | ADR 0037, 0005 |
| Formula needing a macOS-specific source build | **not here** — `homebrew.brews` there | ADR 0037, 0005 |
| Font | **not here** — nix-packages' `modules/darwin/fonts.nix` | ADR 0037 |
| New tool's configuration file | `config/<tool>/` + a `link` entry in `modules/home/payloads/shared.nix`, or `darwin.nix` when the tool is macOS-specific | ADR 0020, 0034 |
| Editing an existing tool's configuration | the file under `config/<tool>/` | ADR 0020 |
| Environment variable, `PATH` entry, launchd agent | `modules/home/base.nix` | ADR 0006 |
| macOS system default or keybinding | `modules/darwin/macos.nix` | ADR 0017 |
| Neovim configuration | the files under `config/nvim/` | ADR 0021 |
| Agent skill for every repository (user scope) | `config/agents/skills/<name>/SKILL.md` + its name in the `skills` list of `modules/home/payloads/shared.nix`, which links it into both agents | ADR 0028, 0034 |
| Instructions every agent session loads (user scope) | `config/agents/instructions.md` — already placed as `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` (a store copy, live at the next switch); keep it to pointers, the substance belongs in a skill | ADR 0033, 0034 |
| Agent skill for this repository only (project scope) | `.claude/skills/<name>/SKILL.md` + a `!.claude/skills/<name>` line in `.gitignore` + a `.codex/skills/<name>` symlink | ADR 0019 |
| `flake.lock` | **not here** — use `lock-review` | ADR 0011 |

Everything user-facing belongs to Home Manager; the darwin layer holds only
what the system requires (ADR 0006). `programs.*` is **not** the default form
for configuration — plain files are, and `programs.*` is reserved for cases
that need a Nix value or a Nix-side integration, such as `programs.direnv`
(ADR 0020).

### What is installed lives in nix-packages

[hypatia-tile/nix-packages](https://github.com/hypatia-tile/nix-packages)
declares the packages, Homebrew, fonts, `nixpkgs` and the overlays, and this
flake imports it as an input (ADR 0037). A row above marked **not here** is
made there:

- **From a session in that checkout,** where its own `AGENTS.md` applies, as
  a PR there. Do not edit it from a session here.
- **A tool that needs both sides** is added package first, then config, and
  removed config first, then package, so neither repository is broken in
  between. Adding: the PR there merges, then a branch here moves the input
  and adds the config. Removing: the config leaves here first.
- **Moving the input** is a commit that changes `flake.lock` alone (ADR
  0011). Its command is `nix flake update nix-packages`, which agents are
  denied; hand it to the owner, or let the weekly lock PR bring it.
- **The closure diff of that commit** is the evidence: it must show the
  package change and nothing else. Until `preflight` can build against a
  local nix-packages checkout (#310, stage 4), this is the first point at
  which this host is built with the change.

### Traps that have already cost a PR

- **Declaring a directory hands the whole directory to this repository.** If
  the tool writes runtime state into its own config directory, declare the
  specific files instead (as `herdr/config.toml` and the zsh payload do).
  Getting this wrong does not fail the build: whatever the tool writes lands
  in this repository's working tree, where `git status` is the only thing
  that reports it.
- **A symlink Home Manager did not make blocks the switch.** If the new target
  is already a symlink from something else, activation aborts before linking
  anything; remove it first (`docs/operations.md` §2).
The next two apply to nix-packages' `homebrew.nix`; they stay here because
the switch that fails is this host's.

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
| New config file | `readlink -f ~/.config/<tool>/…` resolves into this checkout, **and** the tool is run once to confirm it actually reads the setting |
| Edited config | the specific behavior that changed, exercised directly |
| User-scope agent skill | after the switch, `readlink -f ~/.claude/skills/<name>` and `readlink -f ~/.codex/skills/<name>` both resolve into this checkout, and `/skills` in a **new** Claude Code session and a **new** Codex session lists it. For Codex, quit every running Codex process first. At the ADR 0028 cutover the first `/skills` checks listed none of the new skills while a Codex process started before the change was still running, and a later fresh start listed all of them; the stale process is the likely cause, not a confirmed one |
| Session variable / `PATH` | open a **new** shell and `echo $VAR` — the value arrives via `hm-session-vars.sh`, sourced from `config/zsh/.zprofile` |
| macOS default / keybinding | `activateSettings -u`, then `bin/check-symbolic-hotkeys.sh` (compares the live domain with the declaration, ID by ID — macOS writes this key itself, see ADR 0030), then a behavior spot-check (`docs/operations.md` §1) |

## Rules

- **Never run `darwin-rebuild switch`, any activation script, or `sudo`.**
  Applying is the owner's manual step (ADR 0003, ADR 0015).
- **Commit on the feature branch without asking, and never push** (ADR 0036).
  Report each commit: the branch, its short hash and subject, and that it is
  not pushed.
- If the change turns out to need a new decision rather than an application of
  an existing one, stop and raise an ADR with `adr-new` instead of deciding it
  inside a configuration commit.
