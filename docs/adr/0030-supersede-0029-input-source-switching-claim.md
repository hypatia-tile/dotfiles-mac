# 0030. Supersede ADR 0029's input-source-switching claim

- Status: Proposed
- Date: 2026-09-22

## Context

ADR 0029 closes with this consequence:

> Input-source switching by keyboard stays unavailable: symbolic hotkeys 60 and
> 61 (Ctrl+Space, Ctrl+Opt+Space) are disabled in `modules/darwin/macos.nix` to
> free those chords for editors.

The premise is true and the conclusion is false. Measured on 2026-09-22, while
carrying out 0029's own manual post-switch steps:

- `modules/darwin/macos.nix` declares `60` and `61` as `enabled = 0`, and has
  since ADR 0017.
- The live system had both as `enabled = true`
  (`/usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys:60:enabled"`).
- `Ctrl+Space` switched input sources system-wide, so it reached neither kitty
  nor Emacs — where it is `skkeleton`'s neighbour chord and Emacs's
  `set-mark-command`.

Nobody edited a keyboard shortcut. The only action taken was adding macSKK as a
second input source in System Settings, which is 0029's first manual step.
macOS enables the input-source switching hotkeys as a side effect of there
being something to switch between.

This is not the drift `docs/operations.md` §1 already warns about. That caveat
says a shortcut changed *in System Settings* is reverted at the next switch,
and names the owner as the other writer. The new fact is that **macOS writes
this key on its own**, as a side effect of an action that is not about
keyboard shortcuts at all.

The mechanism is in `macos.nix`'s own header: the declaration is applied
**at system activation**, as a whole-dictionary `defaults write`. It asserts a
state at a moment; it does not hold it. Between switches the repository's view
of which chords are free can be wrong, and nothing in the flake can notice —
`nix flake check`, the closure build and the closure diff all pass, because
none of them reads the live machine.

ADR 0029 names this shape exactly, as its reason for *not* declaring macSKK's
direct-input list: "the list is written from both ends … a place where the
repository is not the only writer". The same shape turns out to hold for
`AppleSymbolicHotKeys`, a key the repository does declare.

## Decision

Supersede the consequence quoted above. Keyboard input-source switching is
**available by default and must be turned off deliberately**; the declaration
in `macos.nix` is what turns it off, and it does so only when a switch runs.

`modules/darwin/macos.nix` is unchanged: `enabled = 0` for 60 and 61 is still
the intended state, and this ADR corrects what was claimed about its effect,
not the declaration itself.

The drift is caught by a check, not left to be noticed:
`bin/check-symbolic-hotkeys.sh` evaluates the declaration for this host and
compares it with the live `com.apple.symbolichotkeys` domain, reporting every
ID that disagrees — a changed `enabled`, a rebound `parameters`, or a declared
ID absent from the domain, which can only mean something rewrote a dictionary
that activation writes whole. It replaces the manual "`defaults read
com.apple.symbolichotkeys AppleSymbolicHotKeys` matches `macos.nix`" step the
`config-change` skill carried, which asked the reader to compare thirty
entries by eye.

It reads the live machine, so it is **not** part of `preflight` and CI never
runs it — a check that needs this machine cannot be a gate on a pull request.
It belongs to the post-switch steps, alongside the behavioral keybinding
checks that ADR 0017 already made manual.

Two alternatives were weighed and rejected. **Recording the failure mode
without a check** was the cheaper option and is what ADR 0029 argues for in its
own case, on the grounds that a loud failure needs no detector; it is rejected
here because the lesson has now landed three times (the whole-dictionary
replacement caveat, 0029's direct-input list, this) and the general case — any
declared ID, not these two — is worth catching rather than re-diagnosing.
**Declaring 60 and 61 enabled** and giving up the chords is rejected because
ADR 0017 disabled them deliberately and macSKK needs no input-source
switching: `C-j` and `l` change mode inside the single source.

## Consequences

The repository's record matches the machine: a reader of 0029 no longer
concludes that these chords are safe for an editor to claim.

**A declared `system.defaults` key is an assertion, not an invariant**, and
this generalises past keyboard shortcuts. Any key macOS or an application also
writes will drift between switches, silently as far as every build-time gate is
concerned. The check added here covers one such key; the lesson is not confined
to it, and a second contested key would want the same treatment rather than a
second diagnosis.

Expect recurrence: adding any further input source re-enables 60 and 61, and
the manual step of turning them off belongs beside 0029's other post-switch
steps in whatever records that checklist.

Nothing here is enforced by CI, by `nix flake check`, or by the closure diff,
and that is accepted for the same reason 0029 accepted partial
reproducibility: the alternative is holding a key that the operating system
will write back. What changes is that the disagreement is now a command away
instead of a diagnosis away.
