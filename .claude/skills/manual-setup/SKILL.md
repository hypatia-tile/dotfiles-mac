---
name: manual-setup
description: The steps this machine needs that the flake cannot declare — application state inside a sandbox container, a preference macOS writes back, anything a switch does not place. Use when setting up a fresh machine, after installing something whose configuration lives outside the flake, or when the owner asks what manual steps this machine still needs.
---

# manual-setup

Everything here is state the flake **knowingly** does not own. A switch does
not place it, `nix flake check` does not see it, and the closure diff does not
move when it is missing — so a fresh machine comes up with the package
installed and the configuration absent, and nothing says so.

That is a deliberate trade, not a gap to close: ADR 0029 rejected declaring
macSKK's settings because the container is not a domain, because the owner's
own gestures write the same key, and because a directory payload would delete
the runtime state the tool writes beside it. What the trade costs is exactly
this file.

**These steps are the owner's.** Several of the paths below are inside a
sandbox container, which TCC refuses to an agent's shell — an agent reading
`Operation not permitted` there is the boundary working, not a fault to route
around.

## Adding an entry

An entry belongs here when a change lands in the flake but the working result
needs a hand afterwards. Record four things, in this order: **what** to do,
**where** the state lands, **what proves it worked**, and **what makes it come
undone**. The last one is what turns a checklist into knowledge — an entry that
only lists clicks gets re-derived the first time it silently reverts.

## macSKK — the system input method

Declared: the cask, in `modules/darwin/homebrew.nix`. Everything else below is
by hand (ADR 0029). Do the steps in order — each one depends on the last.

### 1. Add the input source

System Settings → キーボード → 入力ソース → 編集 → `+` → 日本語 →
**macSKK (ひらがな ▼あ)**. Add ひらがな alone; `C-j` and `l` change mode inside
the one source, so macSKK's own ABC entry is redundant. If macSKK does not
appear in the list, log out and back in — the cask installs into
`/Library/Input Methods`, and the input-source list is read at login.

This is what first launches macSKK and creates its container. Nothing in step 2
exists until this is done.

Proof: `defaults read com.apple.HIToolbox AppleSelectedInputSources` names
`net.mtgto.inputmethod.macSKK.hiragana`.

**Read `AppleSelectedInputSources`, not `AppleEnabledInputSources`.** Measured
on 2026-09-22: the enabled list still showed only `ABC` while macSKK was
selected and running. It is written lazily and will state the opposite of the
truth.

### 2. Place the dictionary

Copy `~/.local/share/skk/SKK-JISYO.L` — the copy this flake places for
skkeleton — into

```text
~/Library/Containers/net.mtgto.inputmethod.macSKK/Data/Documents/Dictionaries
```

then enable it in macSKK's settings. The source is a Nix store path
(`r--r--r--`, owned by root), so make the copy writable afterwards if macSKK
complains.

The duplication is deliberate: macSKK writes its own user dictionary
(`skk-jisyo.utf8`) into the same directory it reads from, which is why the
directory cannot be a payload (ADR 0029, #94).

Proof: conversion works in an application that is *not* in the direct-input
list — a browser, Slack. Without the dictionary macSKK types kana and converts
nothing.

### 3. Register 直接入力 for kitty and Emacs

With **each application frontmost**, open the input menu in the menu bar and
choose **「(アプリ名)で直接入力」**. macSKK records the frontmost application's
Bundle Identifier, so the order matters.

| Application | Bundle Identifier |
|---|---|
| kitty | `net.kovidgoyal.kitty` |
| Emacs | `org.gnu.Emacs` |

kitty exists both in `/Applications` and under Home Manager Apps; the Bundle
Identifier is the same, so one registration covers both.

**Start Emacs with `em`, not `emacs`.** This is the part that reads like a
working setup and is not. macOS gives a process the Bundle Identifier of the
bundle it was *started from*, and nixpkgs' `bin/emacs` is a plain executable
outside `Emacs.app` — a different file from the bundle's own binary. So a
terminal `emacs` carries no Bundle Identifier at all, macSKK has nothing to key
to, and 「Emacsで直接入力」never appears in the menu. `em` is
`open -b org.gnu.Emacs` and goes through the bundle.

This changed silently at ADR 0031. emacs-plus's `bin/emacs` was a shell wrapper
that `exec`'d the bundle's binary, so the terminal command used to carry
`org.gnu.Emacs` and the difference never showed.

`org.gnu.EmacsClient` was in this table until ADR 0031 and is gone: that Bundle
Identifier belonged to `Emacs Client.app`, which emacs-plus shipped and nixpkgs'
Emacs does not — `path to application id "org.gnu.EmacsClient"` now fails
outright. Running `emacsclient` in a terminal needs no registration of its own,
because the frontmost application there is kitty.

**Skipping this is the loud failure.** Both applications bind `C-j` —
skkeleton in Neovim, ddskk in Emacs — and an input method that is merely in
its ASCII mode still swallows that chord. Direct mode declines the event
instead of consuming it, which is why macSKK was chosen over AquaSKK; measured
on this machine on 2026-09-22, after a session of typing around the problem
the wrong way.

Proof: `C-j` in Neovim inside kitty toggles **skkeleton**, and plain letters
stay plain.

### 4. Turn input-source switching back off

Adding an input source makes macOS re-enable symbolic hotkeys 60 and 61
(`Ctrl+Space`, `Ctrl+Opt+Space`) — against the `enabled = 0` that
`modules/darwin/macos.nix` declares, and without anyone touching a keyboard
shortcut. `Ctrl+Space` is then taken from kitty and Emacs system-wide.

Turn them off: System Settings → キーボード → キーボードショートカット →
入力ソース → clear both entries. Then:

```sh
bin/check-symbolic-hotkeys.sh
```

Proof: the script reports every declared ID matching the live domain. Run it
after adding **any** input source, not only this one — ADR 0030 records why the
declaration cannot hold this key on its own.

### What makes it come undone

- Adding another input source, ever: step 4 again.
- Removing the cask from `homebrew.nix`: the application goes, the container,
  the dictionary and the input source stay behind.
- A fresh machine: all four steps, in order.

## Emacs binary cache — the substituter Nix refuses to be told about

Emacs comes from `hypatia-tile/emacs-flake` (ADR 0031), patched, so it is not in
`cache.nixos.org` and is served from `hypatia-emacs.cachix.org` instead. Without
that substituter the package still builds — it just takes twenty minutes, on
this machine, every time the pin moves.

The flake cannot declare it. `substituters` and `trusted-public-keys` are
restricted settings, this machine's Nix client is not a trusted user
(`nix store info --json` → `"trusted": 0`), and `/etc/nix/nix.conf` belongs to
the installer, which ADR 0014 keeps nix-darwin away from (`nix.enable = false`).
A cache named in the user's `nix.conf`, on the command line, or in the flake's
`nixConfig` is dropped with at most a warning.

### What to do

```sh
sudo tee /etc/nix/nix.custom.conf >/dev/null <<'CONF'
extra-substituters = https://hypatia-emacs.cachix.org
extra-trusted-public-keys = hypatia-emacs.cachix.org-1:01hQJcXQlX0AFv1UpAL7v9zQNhoDT0bJzoNaAzABEzQ=
CONF
sudo tee -a /etc/nix/nix.conf >/dev/null <<'CONF'
!include /etc/nix/nix.custom.conf
CONF
sudo launchctl kickstart -k system/org.nixos.nix-daemon
```

The values go in their own file and are included, so later additions never
touch the installer-owned one again. `!include` does not fail when the file is
missing. The **daemon** performs substitution, so it is the daemon that has to
be restarted.

`/etc/nix/nix.custom.conf` alone does nothing on the Nix installed here:
upstream Nix does not read that path — it is a Determinate Nix feature, and
`determinate-nixd` being present does not make the running Nix Determinate's
(`nix --version` says plain `Nix`). Nothing warns that a config file went
unread, which is the whole reason this entry exists.

### Where the state lands

`/etc/nix/nix.custom.conf` and one appended line in `/etc/nix/nix.conf`. Both
root-owned, outside every payload and every module. `nix.conf` holds only the
`!include`; the values live in `nix.custom.conf` alone.

The same substituter and key are necessarily written in two other places, and
**nothing checks that the three agree**:

| Where | Why it cannot be shared |
| --- | --- |
| `.github/workflows/ci.yml`, the flake job | A GitHub runner configures Nix from the workflow and cannot read this machine |
| `hypatia-tile/emacs-flake`'s README | Canonical for anyone else consuming that flake, and readable before this repository is checked out |

If the cache is ever recreated, those are the places to change alongside this
one. Getting it wrong costs a slow build, not a wrong one: a key that does not
match makes Nix refuse the cache and fall back to building, and signature
verification is what stops a mismatch admitting anything else. That is why the
three copies are accepted rather than machinery built to reconcile them.

### What proves it worked

```sh
nix config show | grep -E '^(substituters|trusted-public-keys) '   # the cache is listed
nix build --dry-run github:hypatia-tile/emacs-flake#default        # "will be fetched"
```

`--dry-run` printing **nothing** is not success: it means the path is already in
the local store, so the test proved nothing. `nix store delete` it first, or
trust only the `substituters` line.

### What makes it come undone

- **A Nix upgrade.** `/etc/nix/nix.conf` is installer-owned and can be
  overwritten, taking the `!include` with it. Emacs is then rebuilt locally
  instead of fetched — twenty silent minutes, with nothing to say why. Re-check
  this entry after any Nix upgrade.
- A fresh machine: both files, then the daemon restart.
- Becoming a trusted user would make the flake's own configuration work instead,
  and is deliberately not done: it would let any flake name a substituter.

## Only one Emacs may be registered with LaunchServices

macSKK keys 直接入力 to a Bundle Identifier, and every build of Emacs claims the
same one, `org.gnu.Emacs`. In Nix each build is its own store path, so each is a
separate LaunchServices registration under that identifier — and which one
`org.gnu.Emacs` resolves to is **not** something the version decides. Measured on
this machine: a leftover 30.2.50 won over the installed 31.1.

When it resolves to the wrong build, `em` opens the wrong Emacs and macSKK
registers 直接入力 against a binary that is not the one being used.

**This recurs on every Emacs bump.** A new store path is registered while the old
one stays registered for as long as any generation still roots it.

### What to do

Ask what it resolves to — this does not launch anything:

```sh
osascript -e 'POSIX path of (path to application id "org.gnu.Emacs")'
```

If it is not the current build, the registration has to go, and **editing the
database does not work**. Both of these were tried and neither held: `lsregister
-gc` left the entry in place, and `lsregister -u <path>` removed it only until
the next rescan put it back with a fresh id. As long as the bundle is on disk it
comes back. `lsregister -kill` no longer exists, and `-delete` needs a reboot.

Removing the store path is the only thing that works:

```sh
sudo nix-collect-garbage --delete-older-than 30d   # drop the generations rooting it
nix-collect-garbage --delete-older-than 30d
nix store delete /nix/store/<old-emacs-path>       # once nothing roots it
```

`--delete-older-than` rather than `-d`: `-d` drops every older generation and
with it every rollback target. Thirty days left this machine three recent ones
and still freed 47 GB of July.

`nix-store --query --roots <path>` names what is holding it. A path with no roots
listed can go straight to `nix store delete`.

### Where the state lands

The LaunchServices database, which nothing here declares and nothing checks.

### What proves it worked

The `osascript` line above returns the current store path, and
「Emacsで直接入力」appears in the macSKK menu with Emacs frontmost.

### What makes it come undone

Every Emacs bump: a new store path registers, the old one stays registered for as
long as a generation roots it, and the resolution can land on either. Check it
after any switch that moved Emacs.

### What else it took, once

Moving off emacs-plus left two real application copies behind in
`/Applications` — `Emacs.app` and `Emacs Client.app`, both 30.2, put there by a
script that copied them out of the Cellar. `brew` cleanup removed the Cellar and
so left them unable to launch (`Library not loaded: libtiff.6.dylib`) while they
went on claiming `org.gnu.Emacs`. They were deleted by hand; a fresh machine
never has them.

## Recompile the Emacs packages after an Emacs version change

`~/.emacs.d` is its own repository and outside this flake, but a change *here*
can break it, so the step belongs here.

A `.elc` carries the macro expansion of the Emacs that compiled it. Change the
Emacs and every installed package's `.elc` is a stranger to it — while the
`.eln` beside it is compiled from source by the *new* Emacs. The two disagree,
and which one answers depends on load order.

Measured going from 30.2 to 31.1: `define-globalized-minor-mode` renamed the
variable it generates from `<mode>-set-explicitly` to `<mode>--set-explicitly`,
so `envrc.elc` defined the old name while the freshly built `envrc.eln` used the
new one. The symptom was
`Error running timer: (void-variable envrc-mode--set-explicitly)` — a name that
appears nowhere in either repository, from a timer, with nothing pointing at the
package or at the version change.

### What to do

```sh
emacs --batch -l ~/.emacs.d/init.el --eval '(package-recompile-all)'
```

Then restart Emacs: a process that already loaded a stale `.elc` keeps it.

### Where the state lands

`~/.emacs.d/elpa/*/*.elc`, and a new `~/.emacs.d/eln-cache/<version>-<hash>/`
which Emacs fills on its own.

### What proves it worked

No `.elc` claims the old Emacs:

```sh
head -c 120 ~/.emacs.d/elpa/*/*.elc | grep -o "in Emacs version [0-9.]*" | sort -u
```

Third-party warnings during the recompile are not failures — ddskk's `ccc.el`
has no `lexical-binding` cookie and AUCTeX's `bib-cite.el` calls an obsolete
function, both upstream and both harmless.

### What makes it come undone

Any Emacs version change, which now arrives through `flake.lock` rather than by
hand — so it can arrive without anyone deciding to change Emacs.

## Install the Git hooks of this repository

The verification gates run as Git hooks (ADR 0032): tracked stubs in
`.githooks/` enter the check devShell and hand over to Lefthook, which runs the
checks `lefthook.yml` assigns to each stage. Git never takes hooks from a
clone, so a fresh checkout runs none of them until it is told where they are.

### What to do

From the repository's main checkout:

```sh
git config core.hooksPath .githooks
```

`lefthook install` is deliberately not used: it writes its own scripts into
the hooks path instead of using the tracked stubs.

### Where the state lands

One line in `.git/config`, which is local to this clone and never committed.
A linked worktree shares it.

### What proves it worked

```sh
bin/hooks-health.sh           # every line ok, exit 0
git hook run pre-commit       # runs the checks on what is staged; exit 0 when nothing is
```

A commit then prints Lefthook's summary of the checks that ran.

### What makes it come undone

- A fresh clone, which has no `.git/config` of its own.
- `git config --unset core.hooksPath`. `lefthook install` cannot undo it by
  accident: it refuses while the setting is present (Lefthook 2.1.14).
- **An agent sandbox** does not undo the setting, but can stop the hooks from
  reaching Nix. Inside cursor-agent's sandbox the hook cannot connect to the
  Nix daemon and fails, which refuses the commit. Commits made through it run
  outside the sandbox (#196). Codex cannot write `.git` inside its sandbox at
  all, so its commits are already escalated.
