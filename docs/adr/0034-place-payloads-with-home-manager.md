# 0034. Place payloads with Home Manager and retire the projector

- Status: Accepted
- Date: 2026-10-12

## Context

ADR 0026 replaced working-tree symlinks with a projector, `bin/project.sh`,
to win back the one property ADR 0021 had given up: **prevention**, a
`~/.config` that cannot be edited in place. It delivered (#76): every payload
except `nix` and `nvim` is a read-only copy, and edits still go live on save
through a Neovim `BufWritePost` hook.

ADR 0026 also named its main risk:

> The projector inherits work Home Manager was doing: orphan cleanup, collision
> backup, and knowing what the previous run placed. … reimplementing them
> badly is the most likely way this goes wrong.

That is what happened. #85, #87, #91, #94 and #96 are all defects of the
projector or its declaration, several of them `hazard` or `blocking`, one of
which left the machine with nothing placed. Since 2026-09-08, `bin/project.sh`
and `modules/payloads.tsv` took 9 commits, against 0 to 3 for most of the
payloads they place. Owning the placement code has cost more than the
configuration it places.

Weighed against that, prevention is worth less than it was assumed to be. The
other half of the requirement in #76, **audit**, survives without it: with
working-tree links an edit at the deployed path *is* an edit to the
repository, and `git status` reports it. `~/.config/nvim` has stayed a Home
Manager out-of-store link throughout, for the reasons in #76, and has caused
none of the trouble above.

There is one place where prevention is not a general preference but the point.
ADR 0033 made the user-scope agent instructions a `copy` because "a safeguard
the guarded agent can rewrite is not one". That reason does not depend on the
projector.

The projector is not only this Mac's. It runs on the NixOS host as well (#192),
and as of 2026-10-12 that host's Home Manager is declared, as a NixOS module,
in `hypatia-tile/nixos-config`. A Home Manager module from this repository can
therefore be consumed there, which was not possible when ADR 0026 was written.

Measured before deciding:

- During the ADR 0021 period of working-tree links (2026-09-05 to 09-08), no
  tool wrote state into a linked directory: `.gitignore` gained no `config/`
  entry. lazygit's `state.yml`, the case ADR 0021 expected, is written to
  `~/.local/state/lazygit`, not to its config directory.
- zsh-abbr's `abbr add` and `abbr erase` rewrite the abbreviations file with an
  `mv` over the path, which replaces a symlink with a regular file
  (`modules/payloads.tsv`).
- The previous generation's activation runs
  `${common.checkoutPath}/bin/project.sh` by its checkout path, not from the
  store. Rolling back to it after the script is deleted fails, and leaves
  nothing placed: Home Manager has removed its links as orphans, and the
  projector that would replace them is gone.
- `~/.zshenv.hm-bak` and `~/.hammerspoon.hm-bak` already exist. Home Manager
  aborts activation, before linking anything, when a backup it needs to make
  already exists.

## Decision

**Home Manager is the only mechanism that places payloads.** This repository
keeps no placement code of its own. Prevention is given up, except for the
agent instructions.

**This is an interim choice, made because it is the smoothest to operate now —
not a commitment to Home Manager.** What keeps it interim is how Home Manager is
used, not a date or a trigger:

- Home Manager only places files. Payloads stay plain files under `config/`
  (ADR 0020), and are not generated through `programs.*`.
- The declaration is a flat list of target-to-source entries per module, so
  leaving Home Manager means moving that list to another mechanism, nothing
  more.
- Whether a tool moves to `programs.*` is decided per tool by ADR 0020's
  criterion. A tool that does leaves the payload list, so that no path has two
  owners (ADR 0025).

**Two dispositions, both Home Manager's own.**

- `config.lib.file.mkOutOfStoreSymlink` into the checkout is the default.
- A store copy (`source = <path in the flake>`) for `~/.claude/CLAUDE.md` and
  `~/.codex/AGENTS.md`, for ADR 0033's reason. A change to them goes live at the
  next switch.

**Granularity is carried over from `modules/payloads.tsv` unchanged.** It was
established by measuring where each tool writes its runtime state (#94,
ADR 0021), and the placer does not change that.

| Granularity | Targets |
|---|---|
| directory | `git`, `tmux`, `kitty`, `alacritty`, `aerospace`, `lazygit`, `~/.hammerspoon`, `zsh/{modules,complete,functions}` |
| file | `herdr/config.toml`, `zsh/{.zshrc,.zprofile,.zshenv,abbreviations}`, `~/.zshenv` |
| per skill | `~/.claude/skills/<name>`, `~/.codex/skills/<name>` |
| store copy | `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` |

**`abbreviations` is a link like the rest, and `abbr add` and `abbr erase` are
not used.** The file in the repository is the editing surface, as it has been
since #148; an abbreviation for one shell is added with `abbr add --session`.
The rule is stated in the file's header.

**The declaration is two module files, one shared and one macOS-only.** Both
take the checkout's path as an option, because it differs between hosts. There
is no platform conditional inside either: a host imports what applies to it.
Which file a payload belongs in is decided by whether its tool is
macOS-specific, not by whether a host happens to have it installed today.

- Shared: `git`, `tmux`, `kitty`, `alacritty`, `herdr`, `lazygit`, zsh,
  `~/.zshenv`, the user-scope skills, the agent instructions, `nvim`, and the
  SKK L dictionary from nixpkgs.
- macOS-only: `aerospace`, `~/.hammerspoon`, `nix`.

**`nixos-config` consumes the shared module as a `flake = false` input**,
importing the file by path. This repository gains no flake output. The module
needs no input of this flake, and taking this flake as a flake input would put
its nixpkgs, nix-darwin and Home Manager into `nixos-config`'s lock — the
coupling #81 argues against. `nixos-config` drops its own declaration of the
`nvim` link, and of the dictionary if it has one.

**The migration runs in three steps, and the projector is deleted last.**

1. A pull request here moves the declaration into the two modules and switches
   this Mac to them. It removes the `projection.nix` import and the Neovim
   hook, which would otherwise overwrite Home Manager's links on every save. It
   keeps `bin/project.sh` and `modules/payloads.tsv`, so that rolling back to
   the previous generation still places everything.
2. A pull request in `nixos-config` imports the shared module, and the NixOS
   host is switched.
3. Once both hosts pass the post-switch check, a second pull request here
   deletes the projector, its declaration, the gates and hook check that serve
   it, and the documentation that describes it. It follows the check without a
   waiting period.

Between steps 1 and 3, `bin/project.sh` is not run by hand; `docs/rollback.md`
says so. No guard is added to the script for that window, since it is about to
be deleted.

Before step 1 is switched, the owner reviews and removes `~/.zshenv.hm-bak` and
`~/.hammerspoon.hm-bak`.

The post-switch check, on each host:

- every linked target resolves into the checkout, and the two agent
  instruction files resolve into `/nix/store`;
- the `*.hm-bak` left by the migration are the projector's read-only copies
  only, identical to the repository; they are made writable and removed;
- a new login shell starts, `abbr list` matches the declaration, and `history`
  and `.zcompdump` are intact;
- git, tmux, kitty, AeroSpace, Hammerspoon, herdr and lazygit each read their
  configuration, where the host has the tool;
- a new Claude Code session and a new Codex session list every user-scope
  skill;
- after using those tools, the checkout's `git status` shows nothing
  unexpected.

**This supersedes ADR 0026 in full.** It supersedes ADR 0028's placement of
skills by the projector, together with the two refusals that existed to protect
that placement (a symlink in a target's parent path, and placement from a
worktree). It supersedes ADR 0033's choice of the projector's `copy` for the
agent instructions, and keeps the reason for it. ADR 0021's placement is
restored for payloads, and the prevention gap ADR 0025 kept visible is closed
by accepting it, not by filling it.

## Consequences

- No placement code remains in this repository. Collision checks, backups and
  orphan cleanup are Home Manager's, and `checkoutPath` is fixed in the
  declaration, so the worktree hazard ADR 0028 measured cannot occur.
- One declaration serves both hosts. The question #192 left open — which
  payloads are for every host — is answered by which file a payload is in.
- Adding or removing a payload or a skill needs a switch, the owner's step, on
  each host. On NixOS it also needs `nixos-config`'s lock to move, and so does
  a change to the agent instructions. Editing the content of a linked payload
  or skill needs neither: it is live on save, on any host that has pulled.
- `~/.config` is writable again, through the links. An edit there lands in the
  working tree, and `git status` is the only thing that reports it.
- Tools may start writing state into the working tree, as ADR 0021 warned. None
  did during that period. One that does is handled by narrowing that payload's
  granularity.
- A forgotten `abbr add` replaces the link with a regular file. The next switch
  moves that file to `abbreviations.hm-bak`, so the new abbreviation is lost
  without a word, and the switch after that fails while the backup exists.
- A generation rollback does not revert configuration content, as under ADR
  0021. After step 3, rolling back to a generation from before step 1 needs
  `bin/project.sh` restored from history first. `docs/rollback.md` is rewritten
  in both pull requests: for the window in step 1, and without the projection
  recovery section in step 3.
- What has to change, beyond the projector itself: `bin/check-skills.sh` and
  `bin/check-abbr.sh` read the modules instead of `modules/payloads.tsv`;
  `bin/check-payloads.sh` and `bin/check-nvim-hook-paths.sh` are removed with
  their `lefthook.yml` and CI steps; the `host-environment` skill identifies
  this repository's payloads by a Home Manager link that resolves into the
  checkout, not by the projector's manifest; `config-change`, `AGENTS.md`,
  `CLAUDE.md`, `docs/operations.md`, and the comments in payloads that name the
  projector are updated.
- `nixos-config` depends on two file paths in this repository. A rename here
  breaks its evaluation loudly rather than silently, at its next lock update.
- #81 rejects indirection built for a second environment. The module option
  for the checkout path is that kind of indirection, kept to one value for a
  host that exists rather than a hypothetical one.
