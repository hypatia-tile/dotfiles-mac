# 0021. Place config payloads as working-tree symlinks

- Status: Accepted
- Date: 2026-09-05

Promoted to Accepted by shinokun, 2026-09-05.

## Context

`modules/home/files.nix` places every payload under `config/` from a path
inside the flake, so the files that land in `~/.config` are read-only copies in
the Nix store. Changing one line of zsh or Neovim configuration therefore
requires a closure rebuild, a CI run, a pull request and a switch before it can
be tried.

The cost is not speed. A rebuild after a one-line config edit takes **8.18
seconds**. It is the shape that is wrong: the content of a configuration file
does not belong to the lifecycle of building and installing a tool, and the
store placement drags it through that lifecycle anyway. What is wanted is the
file *placement* Home Manager performs, without the content pinning that comes
with it.

Issue #58 asked which payloads are edited often enough to justify
`mkOutOfStoreSymlink`, and answered by edit frequency. Measured, that framing
refutes itself: since the ADR 0018 finalization exactly one payload has been
touched (`config/zsh`, once) against 111 system generations. The question was
wrong rather than the answer.

The property worth protecting is also not what #58 assumed. It is not that the
files are read-only; it is that **this repository is the only surface through
which configuration changes** — no out-of-band drift, nothing fixed in place
and forgotten. A working-tree symlink satisfies that structurally: editing
`~/.config/zsh/.zshrc` *is* editing the repository's file, and `git status`
sees it. Stated as an invariant rather than as a mechanism, live editing and an
immutable `~/.config` stop being in tension.

Neovim is the extreme case. Its config is the pinned non-flake input
`nvim-config` (ADR 0014), so a change means pushing to another repository,
bumping the pin, and a second pull request. `~/.config/nvim` is a
directory-level store symlink, which makes `lazy-lock.json` read-only — the
editor cannot record plugin updates at all. `bin/nvim-dev` and the
`~/.config/nvim-dev` symlink already give an immediate edit loop, but against
`NVIM_APPNAME=nvim-dev`, a sandbox with its own data, state and cache; that
covers trying a change once, not living with it in the editor actually in use.

Prior art: [`hypatia-tile/skills` ADR
0001](https://github.com/hypatia-tile/skills/blob/main/docs/adr/0001-deploy-skills-by-symlink-not-home-manager.md)
took the symlink option for Claude Code skills. ADR 0010 and ADR 0018 set the
precedent for retiring an absorbed repository: archived on GitHub, not deleted,
with the local clone surviving as reference.

Full diagnosis and the alternatives considered are in issue #64, which
supersedes #58.

## Decision

**Place the payloads from the working tree.** `modules/home/files.nix` uses
`config.lib.file.mkOutOfStoreSymlink` pointing at this checkout instead of a
path inside the flake. The declaration of which links exist and where they
point stays in Nix, so the machine does not stop being declarative; only the
content stops being pinned. The checkout's absolute path is added to
`modules/common.nix` alongside the other identity constants.

**Choose link granularity by runtime state, not by preference.** A
directory-level symlink makes the directory itself the repository's, so any
state the tool writes there lands in the working tree. Therefore:

- link **file-by-file, or at a subdirectory that holds no state**, where the
  tool writes into its own config directory;
- link the **whole directory** where the repository owns every entry.

As surveyed today: `~/.config/zsh` holds `.zcompdump` and `history` at its top
level, so those four repository files are linked individually while `modules`,
`complete` and `functions` — repository-owned in full — are linked as
directories, which means a new `config/zsh/modules/*.zsh` needs no switch at
all. `~/.config/herdr` holds logs, `session.json`, `sessions/` and
`.plugins.lock`, so `config.toml` stays linked alone, as it already is. Every
other payload (`git`, `tmux`, `kitty`, `alacritty`, `aerospace`, `lazygit`,
`nix`, `hammerspoon`) is repository-owned in full and is linked as a directory.

**Bring Neovim into this repository.** The rule above cannot hold for Neovim
while its config lives elsewhere, so `nvim-config` is imported with `git
subtree` — preserving its history, since the remote is being retired — and
becomes an ordinary payload at `config/nvim`. The subtree is not a preference;
it is what makes the placement rule apply to Neovim. The `nvim-config` flake
input is removed, and the `nvim-bump` skill, `bin/nvim-bump-check.sh`,
`bin/nvim-dev` and the `~/.config/nvim-dev` symlink are retired with it.

**Archive the absorbed repositories.** `nvim-config` and `dotfiles-linux` are
archived on GitHub following ADR 0010 and ADR 0018: archived rather than
deleted, local clones retained. `dotfiles-linux` consumed `nvim-config` as a
git submodule and has been dormant since 2026-01.

This **supersedes** the clause of ADR 0014 that Neovim config is consumed as
the pinned non-flake input `nvim-config`, together with the consequence it
records that editing it means pushing to that repository and bumping the pin.
ADR 0020 is unaffected in substance: plain files under `config/` remain the
default *form*; this decides their *placement*, which ADR 0020 did not.

Verification and shipping — how CI should test a change whose closure no longer
moves, and whether a switch may precede the pull request — are decided
separately, in ADR 0022.

## Consequences

Editing a configuration file takes effect on save. No rebuild, no CI, no pull
request, no switch stands between a change and trying it. Neovim becomes a
single-repository concern, and `lazy-lock.json` becomes writable *and*
committed, which is what a lockfile wants and what the store placement made
impossible.

The invariant that the repository is the only editing surface is strengthened
rather than weakened: today a change can be made to a store-linked file only by
going through the repository, but a mistake there is invisible until someone
looks; after this, every edit is a working-tree edit that `git status` reports.

The accepted costs:

- **Config rollback becomes a git operation.** `darwin-rebuild switch
  --rollback` no longer reverts configuration content. `git checkout` is finer
  — per file, per hunk, with history — but `docs/rollback.md` is written on the
  opposite assumption and must be rewritten as part of this change.
- **A generation rollback now produces a mixed state**: the closure returns to
  a previous point while the configuration stays current. Naming this in
  `docs/rollback.md` matters more than the rollback command itself, because it
  is read under pressure.
- **The closure no longer describes `~/.config`.** It does not reproduce the
  configuration on a new machine; bootstrapping requires the checkout first.
- **The links dangle if the checkout moves or is removed**, and the machine's
  configuration now depends on a filesystem path recorded in
  `modules/common.nix`. Recovery is re-cloning to that path.
- **The running configuration may be uncommitted.** This is the point rather
  than a defect, but it is the same property seen from the other side, and it
  is why the resting-state invariant belongs in the verification decision.
- **Tools may begin writing state into the working tree.** The survey above
  found no state outside `zsh` and `herdr`, but that absence is partly *caused*
  by the directories being read-only — `lazygit`, for one, writes `state.yml`
  where it can. Expect untracked files to appear after the switch, and handle
  them with `.gitignore` or by narrowing that payload's link granularity.
  Discovering this is a normal outcome, not a failure of the decision.
- **Neovim's `stdpath("data")` discipline must survive.** It was adopted
  because the config directory was read-only; the directory becoming writable
  is not an invitation to write into it. `docs/operations.md` §1 records the
  rule and should keep it while dropping the reason.

`preflight`'s closure diff — the step that proves a change is what it claims to
be — can no longer see configuration changes at all, since the link target is a
path string and the closure does not move. Until the verification decision
lands, the most frequently edited files in the repository are outside that
gate.
