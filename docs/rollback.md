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
| env | `echo $EDITOR` → `nvim`; `echo $JAVA_HOME` → a `/nix/store` path |
| nix | `nix flake metadata ~/ghqrepo/github.com/hypatia-tile/dotfiles-mac` works — if it fails, the user `nix.conf` is missing and flakes are disabled; prefix one-offs with `NIX_CONFIG="experimental-features = nix-command flakes"` |
| nvim | launches; `:echo stdpath('config')` resolves through `~/.config/nvim` |
| brew | `brew list --formula` and `brew list --cask` match what you expect for that generation |

If Home Manager backed a file out of the way during the failed switch, it is
next to the original with a `.hm-bak` suffix; restore it by renaming.
`find ~ -maxdepth 3 -name '*.hm-bak'` finds them.

## If generation rollback is not enough

There is a second, much heavier layer: restoring the pre-cutover setup from
the archived legacy repositories, documented in
[`runbook.md`](runbook.md) §3.

**It is not a rollback of a recent change.** The legacy repositories were last
updated in early July 2026 and are archived. Restoring them returns the
machine to the symlink regime that this flake replaced on 2026-07-14 and
discards everything merged since. Treat it as abandoning the current setup,
not as undoing the last switch — and exhaust generation rollback first.
