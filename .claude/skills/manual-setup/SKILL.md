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
| emacsclient | `org.gnu.EmacsClient` |

kitty exists both in `/Applications` and under Home Manager Apps; the Bundle
Identifier is the same, so one registration covers both.

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
root-owned, outside every payload and every module.

### What proves it worked

```sh
nix config show | grep -E '^(substituters|trusted-public-keys) '   # the cache is listed
nix build --dry-run github:hypatia-tile/emacs-flake#default        # "will be fetched"
```

`--dry-run` printing **nothing** is not success: it means the path is already in
the local store, so the test proved nothing. `nix store delete` it first, or
trust only the `substituters` line.

### How it comes undone

- **A Nix upgrade.** `/etc/nix/nix.conf` is installer-owned and can be
  overwritten, taking the `!include` with it. Emacs is then rebuilt locally
  instead of fetched — twenty silent minutes, with nothing to say why. Re-check
  this entry after any Nix upgrade.
- A fresh machine: both files, then the daemon restart.
- Becoming a trusted user would make the flake's own configuration work instead,
  and is deliberately not done: it would let any flake name a substituter.
