# 0029. Adopt macSKK as the system input method, configured by hand

- Status: Proposed
- Date: 2026-09-22

## Context

This machine has had no system input method since the 2026-07-14 cutover. ADR
0002 put skk outside the migration scope, the inventory found the `aquaskk`
cask unused, and `modules/darwin/homebrew.nix` records its removal at first
activation. Japanese has been typed with skkeleton inside Neovim ever since.

Everything that is not Neovim goes through the Japanese input pad
(`config/hammerspoon/init.lua`, cmd-alt-I): a kitty window running Neovim whose
buffer is copied to the clipboard on `<C-s>`, floated by a rule in
`config/aerospace/aerospace.toml`. Both files carry the comment "this machine
has no system IME" as the reason they exist. The pad closes the gap from the
wrong side — every Japanese string destined for a browser, Slack or a dialog is
written somewhere else and pasted back — and the owner wants the gap closed
from the near side instead.

The constraint that decides which input method: **it must be off in kitty and
Emacs.** Both already bind `C-j` — skkeleton in Neovim, ddskk in Emacs — and an
input method that is merely in its ASCII mode still swallows that chord. Off
has to mean the keystrokes reach the application unprocessed.

Measured on 2026-09-22:

| | macSKK | AquaSKK |
|---|---|---|
| Cask | `macskk` 2.20.0 | `aquaskk` 4.7.3 |
| Requires | macOS 13.3+ | any |
| Per-app bypass | yes, by Bundle Identifier | none |

macSKK's "直接入力" setting records applications by Bundle Identifier and passes
their key input through without conversion; its documentation names `Emacs.app`
as the intended case. Its CHANGELOG entry for v1.9.0 — *directモード時に単語
登録・登録解除でないときは何もせずfalseを返す* — is the part that matters here:
in direct mode the event is declined rather than consumed, `C-j` included.
AquaSKK has no equivalent, which settles the choice.

Three facts about where macSKK keeps its state, all from its documentation:

- settings:
  `~/Library/Containers/net.mtgto.inputmethod.macSKK/Data/Library/Preferences/net.mtgto.inputmethod.macSKK.plist`
- dictionaries:
  `~/Library/Containers/net.mtgto.inputmethod.macSKK/Data/Documents/Dictionaries`
- the input sources (ひらがな ▼あ, ABC ▼A) are added in System Settings →
  キーボード → 入力ソース after installation.

All three are inside the application's sandbox container.

## Decision

Install macSKK as a Homebrew cask (ADR 0005 — it is a GUI application), and
**declare nothing else about it.** Its input sources, its dictionary and its
direct-input list are the owner's manual post-switch steps.

The direct-input list starts as `net.kovidgoyal.kitty`, `org.gnu.Emacs` and
`org.gnu.EmacsClient`, added through 入力メニュー → "(アプリ名)で直接入力" with
each application frontmost.

Three reasons the rest is not declared, rather than one:

- **The container is not a domain.** `system.defaults.CustomUserPreferences`
  writes `defaults write <domain>`; reaching a sandboxed container's plist
  means passing a path instead, against a file `cfprefsd` owns on the
  application's behalf.
- **The list is written from both ends.** The direct-input list grows by a
  gesture in the input menu, which writes the same key. A declared value that
  replaces rather than merges would silently discard entries added that way —
  the `AppleSymbolicHotKeys` lesson (`docs/operations.md` §5) in a place where
  the repository is not the only writer.
- **The dictionary is runtime state.** macSKK writes its user dictionary
  (`skk-jisyo.utf8`) into the same directory it reads `SKK-JISYO.L` from, and
  a directory payload deletes what the tool wrote there (#94).

The SKK L dictionary is therefore placed twice on this machine: once by this
flake at `~/.local/share/skk/SKK-JISYO.L` for skkeleton (`pkgs.skkDictionaries.l`),
and once by hand inside macSKK's container. Whether a symlink from the
container to the store path would work is **unverified** — a sandboxed
application reading through a symlink out of its container is exactly what App
Sandbox is built to refuse — and finding out is not a precondition for this
change. If it does work, it is a later, separate one.

The input pad stays. It is the fallback while macSKK is on trial, and whether
it survives is a question for after the owner has lived with a system IME for a
while, not part of this change.

## Consequences

Japanese becomes typable in every application, and the pad stops being the only
path. The comments in `init.lua` and `aerospace.toml` that justify the pad with
"this machine has no system IME" become false on the day of the switch, so they
are corrected in the same change; the pad's own justification narrows to
"apps where the system IME is unavailable or awkward".

**Reproducibility is partial, and knowingly so.** A fresh machine gets macSKK
installed and nothing configured: no input source, no dictionary, no
direct-input list — three manual steps that are invisible to `nix flake check`
and to the closure diff. They belong in whatever records the post-switch
checklist, not in the flake.

**The failure mode is loud, which is what makes the trade acceptable.** If the
direct-input list is missing or wrong, `C-j` stops reaching skkeleton or ddskk
and the owner notices within one line of typing. There is no silent-wrong
state to detect later.

Input-source switching by keyboard stays unavailable: symbolic hotkeys 60 and
61 (Ctrl+Space, Ctrl+Opt+Space) are disabled in `modules/darwin/macos.nix` to
free those chords for editors. SKK does not need them — one input source, with
`C-j` and `l` switching modes inside it — but adding a second input method
later would have to reckon with it.

`onActivation.cleanup = "uninstall"` now keeps macSKK installed, where before
the same setting is what removed `aquaskk`. Removing the cask from
`homebrew.nix` uninstalls the application; it does not remove the container,
the dictionary, or the input sources left in System Settings.
