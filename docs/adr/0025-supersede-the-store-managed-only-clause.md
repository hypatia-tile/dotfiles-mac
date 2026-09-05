# 0025. Supersede ADR 0001's store-managed-only clause

- Status: Proposed
- Date: 2026-09-05

## Context

ADR 0021 placed config payloads as working-tree symlinks. ADR 0001 forbids
exactly that, by name:

> All managed files are **fully store-managed**. No `mkOutOfStoreSymlink`
> escape hatches: every change, including editor config tweaks, is applied via
> `darwin-rebuild switch`.

and its Consequences accept the cost that follows:

> Editing iteration on frequently-changed configs (e.g. Neovim) requires a
> rebuild per change. This trade-off was made knowingly, preferring purity.

ADR 0021 overturns both and cites neither. It records its relationship to ADR
0014 and ADR 0020 and misses the decision it actually contradicts. The defect
is in the record rather than in the code: the change is implemented, applied
and verified, but a reader of ADR 0001 would find a rule the repository no
longer follows and no trail explaining why.

Worth being precise about what ADR 0001 got wrong, because the answer is
"nothing, at the time". It named the cost accurately and accepted it
deliberately. Three things changed after it:

- **The cost was measured.** A config-only rebuild takes 8.18 seconds. Speed
  was never what made the loop painful, so "preferring purity" was not being
  paid for in the currency ADR 0001 assumed.
- **The real cost arrived later.** ADR 0012 introduced CI, and `config/**` in
  its closure-affecting filter turned "a rebuild per change" into "a pull
  request and a 3–4 minute macOS build per change". ADR 0001 predates that and
  could not have priced it.
- **"Fully store-managed" was a mechanism, and it bought two things, not
  one.** It made the repository the only surface through which configuration
  changes, and it did so in two different senses: *audit* — an out-of-band fix
  is visible — and *prevention* — `~/.config` is read-only, so there is no
  out-of-band fix to find. A working-tree symlink keeps the first and gives up
  the second: editing `~/.config/zsh/.zshrc` *is* editing the repository's
  file, so `git status` reports it, but the file is `-rw-r--r--` and nothing
  stops the edit. ADR 0021 claimed the invariant was satisfied structurally.
  It is satisfied in the audit sense only, and that ADR overstated it.

## Decision

Record that **ADR 0021 supersedes ADR 0001's store-managed-only clause** and
the consequence that accepted a rebuild per change.

The rest of ADR 0001 stands in full and is not weakened: dotfiles-mac is the
single entry point, payloads are vendored here, `dot-link.sh` is retired, and
placement is declared in this flake.

The part of ADR 0001 that matters most is not the clause being superseded but
the reason it existed. Its Context records two systems fighting over the same
files — Home Manager's `programs.*` deliberately disabled to avoid colliding
with `dot-link.sh` symlinks, "a sign of the two systems working around each
other". **`~/.config` has exactly one owner.** That constraint survives
untouched, and any future proposal to place links by another mechanism has to
satisfy it rather than route around it.

## Consequences

The record becomes navigable again: a reader arriving at ADR 0001's
no-escape-hatches rule finds where it was overturned and on what evidence.

It also stops ADR 0021 reading as a destination. Prevention was a real property
of store placement, it is gone, and getting it back while keeping live editing
needs read-only copies rather than symlinks — which symlinks cannot provide,
since permissions live on the target. That is issue #69, and this ADR is what
keeps the gap visible until it is settled.

Nothing changes on the machine. This ADR is bookkeeping, and saying so is
better than dressing it up — but the bookkeeping is the point, since ADRs are
the only durable explanation of why the repository looks the way it does.

The lesson generalises past this instance, and it is the second time in one
session: an ADR that changes an existing arrangement must be checked against
the decisions that *established* it, not only against the ones it happens to
mention. ADR 0021 named ADR 0014 and ADR 0020, both of which it touched
lightly, and missed ADR 0001, which it reversed. The check that would have
caught it is mechanical — grep the ADR directory for the mechanism being
introduced before writing, in this case `mkOutOfStoreSymlink`, which appears
in ADR 0001 in the negative.
