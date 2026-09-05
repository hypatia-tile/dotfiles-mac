# 0026. Project payloads into `~/.config` as read-only copies

- Status: Proposed
- Date: 2026-09-06

## Context

ADR 0021 replaced store copies with working-tree symlinks so that editing a
config file takes effect on save. ADR 0025 records what that gave up. Store
placement had bought two properties:

- **audit** — an out-of-band edit is visible. Symlinks keep this, and improve
  on it: the edit lands in the repository and `git status` reports it;
- **prevention** — `~/.config` cannot be edited at all. This is gone.

Measured after ADR 0021 was applied:

```text
~/.config/zsh/.zshrc     -rw-r--r--  kazukishinohara   ← writable
modules.hm-bak/abbr.zsh  -r--r--r--  root              ← the old store copy
```

A symlink cannot provide prevention, because permissions live on its target and
the target must be writable for editing from the repository to work at all.

The requirement, stated as a property rather than a mechanism (#76): **the
repository governs `~/.config` rather than merely supplying it.** `~/.config` is
a projection — files are placed from here, and the deployed copy is not an
editing surface.

Two facts that were assumed wrong earlier and are load-bearing here:

- **`~/.config` already has two owners.** Home Manager places
  `~/.config/direnv/lib/hm-nix-direnv.sh` from `programs.direnv`, which ADR 0020
  deliberately keeps, plus `~/.local/share/skk/SKK-JISYO.L` from a package
  output. So "retire `files.nix` entirely" was never available. What ADR 0001's
  Context actually describes is two systems claiming the *same* paths — Home
  Manager's `programs.*` disabled to avoid colliding with `dot-link.sh`. The
  constraint is **no path has two owners**, which a partition satisfies.
- **The declaration cannot stay in `files.nix`.** A payload declared there is
  placed by Home Manager; there is no declare-without-placing. Moving the
  declaration out is forced, and it therefore cannot produce two sources of
  truth.

## Decision

Place payloads with a **projector**: `bin/` script, run by hand, that copies
each declared payload into its target and makes it read-only.

**Declaration.** A standalone Nix file outside `files.nix`, read with
`nix eval -f` — 0.15 s, against 0.40 s for a flake app and 4.96 s for anything
that evaluates Home Manager. It stays Nix so the repository keeps one
configuration language and the entries can carry comments.

**Two dispositions, and only two.**

- `copy` — a read-only copy. The default, and what provides prevention.
- `link` — a symlink to the working tree, declared per path, for files a tool
  must write *back into the repository*.

A writable copy is not a third option: `config/nvim/lazy-lock.json` must be
written by the editor **and** committed, and a writable copy diverges from the
repository instead of updating it. It is the only `link` today. Note this
recreates ADR 0021's granularity problem for the same underlying reason — a
directory-level `copy` of `config/nvim` needs that one entry replaced.

**A manifest, and no force-overwrite.** The projector records the paths it
placed. On the next run it removes only what is in the manifest and absent from
the declaration, so a payload deleted from the declaration stops being active
instead of lingering silently. Files it never placed are not touched, which is
what keeps `~/.config/zsh/.zcompdump`, `HISTFILE` and herdr's state safe. A
target that exists and is not in the manifest is **backed up, never
overwritten**. `dot-link.sh` was retired for `rm -rf` + `ln -s`, and this is the
line that keeps the projector from being that script again.

**Staleness is detected and mostly prevented.** The projector takes a `--check`
mode that reports a divergence between the declaration and what is placed;
`preflight` calls it. A `home.activation` entry ordered after `linkGeneration`
runs the projector on every switch, so Home Manager triggers it without placing
anything — no path acquires a second owner. That covers the dangerous
direction: editing and forgetting to sync is self-revealing, because the change
appears not to work, whereas a `git pull` that moves the repository leaves a
stale copy running silently.

**Migration is incremental, and zsh is last.** Ownership divides per path, so
payloads move one at a time: a low-risk one first (`git`, `lazygit`), then the
rest, with `zsh` and `nvim` at the end.

This supersedes ADR 0021's placement *mechanism* for payloads. Its goal is
unchanged and its granularity rule survives in a new form. ADR 0020 is
unaffected: plain files remain the default form.

## Consequences

`~/.config` becomes read-only, so both properties hold at once for the first
time: ADR 0001 had prevention without liveness and accepted that knowingly,
ADR 0021 has liveness without prevention. That is why this is a synthesis
rather than a return to the retired script.

Editing stops being live. A payload edit needs the projector run before it
takes effect — a real regression against ADR 0021, accepted because the tool
must be restarted to see a config change anyway, so the marginal step is small.
The bar it must clear is `sudo darwin-rebuild switch`, not zero, and 0.15 s
clears it by orders of magnitude.

**A broken projection cannot be undone by a generation rollback.** Home Manager
will have released those paths and the projector's output is outside the
closure, so `switch --rollback` restores neither. If the projector breaks
`~/.config/zsh` there may be no working shell to repair it from. Migrating zsh
last is the mitigation; `docs/rollback.md` must be rewritten again, since ADR
0021 told it that configuration is recovered with `git checkout`, and after this
it is recovered by restoring the repository *and re-running the projector*.

The projector inherits work Home Manager was doing: orphan cleanup, collision
backup, and knowing what the previous run placed. `cleanupOrphanLinks` and
`backupFileExtension` exist because these are not trivial, and reimplementing
them badly is the most likely way this goes wrong.

Bootstrapping gains a step. A fresh machine has no projection until the
projector runs, where previously `darwin-rebuild switch` was sufficient — the
activation hook closes this, provided the checkout is present at
`common.checkoutPath`.
