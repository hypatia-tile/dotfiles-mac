# Rollback

Recovery when a `darwin-rebuild switch` leaves the machine worse than before.
Self-contained on purpose: this is read under pressure.

Every command here is the owner's. No automation in this repository switches,
activates, or rolls anything back (ADR 0003).

## Before switching: record the generation

One command, run before every switch, is what makes the rest of this page
work:

```sh
darwin-rebuild --list-generations | tail -5
```

Note the current generation number. Without it you can still roll back one
step, but not to a specific known-good point.

## Roll back

```sh
sudo darwin-rebuild switch --rollback
```

That returns to the immediately previous system *and* Home Manager
generation. To land on a specific one instead:

```sh
sudo darwin-rebuild switch --switch-generation <N>
```

`--rollback` and `--switch-generation` are **flags on `switch`**, not
subcommands — `darwin-rebuild rollback` is not a valid invocation.

### What a generation rollback does *not* undo

**Configuration content.** Since ADR 0021 the payloads under `config/` are
placed as symlinks into this checkout's working tree, not copied into the
store, so a generation holds the *set of links*, never the file contents.
Rolling back restores which links exist; every one of them still resolves to
whatever the working tree says right now.

So a rollback lands you in a mixed state on purpose: an older closure with
current configuration. That is usually what you want — the closure is what
just broke — but if the bad change was in a config file, rolling back the
generation does nothing at all for it. Undo that with git instead:

```sh
git -C <checkout> diff              # what is live right now
git -C <checkout> checkout -- config/<tool>
```

That is finer than a generation rollback, not weaker: per file, per hunk, with
history. But it is a different command, and reaching for the wrong one under
pressure costs time. Ask first which of the two broke — closure or content.

**Uncommitted work.** Because the links resolve to the working tree, the
machine can be running configuration that was never committed. `git status`
in the checkout is part of diagnosing a bad state, not an afterthought.

Rolling back is itself an activation, so it re-runs the previous
generation's Homebrew phase against the previous Brewfile. Packages that the
forward switch uninstalled come back, which means the rollback may need the
network and is not instantaneous. Read the activation output rather than
assuming it completed.

## Verify the rollback took

Open a **new** terminal — much of the user environment is only re-read at
shell startup — and check the areas the failed change touched. As a baseline:

| Area | Check |
|---|---|
| shell | prompt renders; `echo $ZDOTDIR` → `~/.config/zsh` |
| config links | `readlink ~/.config/git` resolves into the checkout, not `/nix/store` — a dangling link here means the checkout moved (ADR 0021) |
| env | `echo $EDITOR` → `nvim`; `echo $JAVA_HOME` → a `/nix/store` path |
| nix | `nix flake metadata ~/ghqrepo/github.com/hypatia-tile/dotfiles-mac` works — if it fails, the user `nix.conf` is missing and flakes are disabled; prefix one-offs with `NIX_CONFIG="experimental-features = nix-command flakes"` |
| nvim | launches; `:echo stdpath('config')` resolves through `~/.config/nvim`, which is a link into the checkout |
| brew | `brew list --formula` and `brew list --cask` match what you expect for that generation |

If Home Manager backed a file out of the way during the failed switch, it is
next to the original with a `.hm-bak` suffix; restore it by renaming.
`find ~ -maxdepth 3 -name '*.hm-bak'` finds them.

## If the projection is missing: recovering from a bare shell

A projection that fails mid-switch leaves payloads neither linked nor placed
(#91). For the zsh payload that means `~/.config/zsh` is empty and the shell
starts with none of its configuration: no prompt to speak of, no history, no
completion, no abbreviations.

**That shell is fully capable, and this is the paragraph to trust when it does
not feel that way.** `PATH` comes from `/etc/zshrc`, which nix-darwin manages in
the system layer — not a payload, not a Home Manager user file — so a projection
failure cannot reach it. Measured with `ZDOTDIR` pointed at an empty directory,
and again with `~/.zshenv` absent entirely:

| | |
|---|---|
| `nix` | `/nix/var/nix/profiles/default/bin/nix` |
| `git` | `/usr/bin/git` |
| `nvim` | `/etc/profiles/per-user/$USER/bin/nvim` |

So the repair is one command, and it needs nothing the bare shell lacks:

```sh
~/ghqrepo/github.com/hypatia-tile/dotfiles-mac/bin/project.sh
```

Type the absolute path — there is no `$PATH` entry for it and no abbreviation
in this shell. Then open a new terminal; the configuration is back.

The projector needs nothing beyond `bash` and the utilities in `/usr/bin`. It
reads `modules/payloads.tsv` with `read`, so no parser and no `nix` are
involved, and it copies from the working tree, not from the store — a store
symlink is something it reads and defers to, never something it creates. Nor
could it have removed `~/.config/nix`: it refuses to place that path at all
(`SELF_DEPENDENCIES` in `bin/project.sh`, #85).

This is not a rollback. The projection is not part of the closure, so
`switch --rollback` does not restore it, and re-running the projector is the
whole recovery.

## If generation rollback is not enough

There is a second, much heavier layer: restoring the pre-cutover setup from
the archived legacy repositories, documented in
[`runbook.md`](runbook.md) §3.

**It is not a rollback of a recent change.** The legacy repositories were last
updated in early July 2026 and are archived. Restoring them returns the
machine to the symlink regime that this flake replaced on 2026-07-14 and
discards everything merged since. Treat it as abandoning the current setup,
not as undoing the last switch — and exhaust generation rollback first.
