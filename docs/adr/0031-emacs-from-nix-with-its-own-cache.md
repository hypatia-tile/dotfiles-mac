# 0031. Emacs from Nix, pinned in its own flake with its own binary cache

- Status: Accepted
- Date: 2026-09-27

## Context

ADR 0005 reserves Homebrew for GUI casks and for packages that genuinely need
Homebrew's macOS-specific builds. Emacs has been in that second category since
2026-07-28, when `emacs-plus@30` replaced the `emacs-app` cask (#20). The reason
recorded then was that a native build was wanted and Homebrew was the easiest
route to one. An earlier attempt at a Nix Emacs left no trace in this
repository at all — it was applied to the machine in system generation 88 and
dropped, uncommitted, days before emacs-plus landed. The recollection is that
the GUI did not work.

Three things found in September 2026 change the balance.

**The Homebrew Emacs stopped being able to natively compile anything, silently,
for four weeks.** `gcc` is a declared dependency of `emacs-plus@30`, and a
`brew bundle cleanup` run had removed it (#57); nothing restores a dependency
deleted out from under an already-installed formula, so it stayed gone. Native
compilation failed on every unit while `native-comp-available-p` kept returning
`t` and every package kept working from byte-code. The only trace was 33
`.eln.tmp` files. #146 carries the repair and the open question of whether
activation should verify that a declared formula's dependency closure is intact.

**That Emacs never had ahead-of-time compilation in the first place.** It is
built `--with-native-compilation=aot`, yet its bundled `native-lisp` holds one
`.eln`. The Nix builds hold over three thousand. The consequence is that 339
bundled Emacs Lisp files are compiled at runtime into the user's cache, which is
also why core files were among the failures above. The cause was not determined
and is not this repository's to fix.

**The GUI blocker from July does not reproduce.** Re-tried at no cost from the
store: window, Japanese font and macSKK all behave, on both the macport and the
Cocoa build of 31.1.

Separately, background transparency was settled. It is not a configuration
problem — no Emacs tried renders `alpha-background` — and the answer is a C
patch, `frame-transparency` from the `d12frosted/emacs-plus` tap, which exists
for Emacs 31 only and patches the NS port, so it applies to upstream 31.1.
Confirmed rendering 2026-09-27. Nothing available through Homebrew provides it:
the tap ships it as a community patch for its own `@31` formula, not as a build
option, and the Emacs in use here is `@30`.

The full record, with what was measured kept apart from what was reasoned, is in
`hypatia-tile/emacs-flake`, `docs/investigation.md`.

## Decision

Take Emacs from Nix, and pin it in a flake of its own,
[`hypatia-tile/emacs-flake`](https://github.com/hypatia-tile/emacs-flake),
consumed here as an input contributing an overlay — the idiom already used for
`neovim-nightly-overlay` and `rust-overlay`.

- The package is `pkgs.emacs` (Cocoa, 31.1) with `frame-transparency` applied,
  vendored in that repository under `patches/` with its GPL-3.0-or-later notice
  and its maintainer credited.
- **Consume it without `inputs.nixpkgs.follows`.** The patch drops the build out
  of `cache.nixos.org`, so that flake publishes to a cache of its own at
  `hypatia-emacs.cachix.org` and its CI does the building. `follows` would build
  `pkgs.myEmacs` from *this* repository's nixpkgs while CI built against the
  flake's lock — a different derivation, so the cache would miss every time.
- `emacs-plus@30` and `imagemagick` leave `homebrew.brews`; `libtool` is added
  to it explicitly.
- Emacs remains outside the Nix closure in one respect: this repository does not
  manage `~/.emacs.d`, which is its own repository (`hypatia-tile/emacs-mac`)
  and stays a live checkout. This ADR is about the program, not its
  configuration.

Declaring the cache is **not** declarable here and stays a manual step. It is a
restricted Nix setting, this machine's client is not a trusted user, and
`/etc/nix/nix.conf` belongs to the installer — which ADR 0014 keeps nix-darwin
away from on purpose (`nix.enable = false`).

## Consequences

**Easier.** Emacs joins the pinned, reproducible part of the system: a
`flake.lock` entry rather than a formula whose dependency tree can be deleted
behind it. The failure mode of #57 and #146 cannot recur for Emacs, because the
whole `emacs-plus@30` runtime tree — around forty formulae — leaves the machine
with it. Ahead-of-time compilation is complete, so bundled Lisp is not compiled
at runtime. Transparency becomes available at all, which no Homebrew route
offered.

**The `libtool` trap, avoided on purpose.** vterm compiles its native module on
first use with cmake and libtool. `libtool` was installed only as
`imagemagick`'s dependency, and `imagemagick` was declared only because
`emacs-plus@30` links against it. Dropping both would have removed `libtool`
silently, and the loss would not have shown until the next time that module had
to be rebuilt — the same shape as #57. Hence the explicit `libtool` entry, whose
only reason is vterm.

**Harder.** Two nixpkgs revisions in the closure instead of one, since the
Emacs input does not follow this repository's. More evaluation and more disk,
neither measured. Emacs also stops moving when the system's pin moves, which is
a benefit and a divergence to remember.

**Riskier.** Three things.

- A `flake.lock` bump can now replace Emacs, with no gate watching — the same
  exposure #153 records for Neovim, and it should be considered together with
  it.
- The patch is recorded as compatible with Emacs 31 only. When nixpkgs moves to
  a later Emacs it may stop applying, and the failure will be a build error in
  that flake's CI rather than anything visible here. Nothing watches for it yet.
- The cache depends on a line in an installer-owned file. A Nix upgrade can
  overwrite `/etc/nix/nix.conf` and drop it, after which Emacs is rebuilt
  locally — twenty minutes, quietly — rather than fetched.

**Accepted trade-off.** Transparency costs a local build whenever the pin moves,
measured at 20m27s on this machine. That cost is moved off the machine rather
than accepted: CI builds it and the cache serves it, so what is actually paid is
a 106 MiB download. The price of moving it is the CI, the cache and the manual
system setting above.

**Not decided here.** Whether `emacs-plus@31` with the same patch would have
been simpler. It would have kept Homebrew in the picture for Emacs and left the
two defects above in place, which is what this decision is getting away from,
but it was not built and compared.
