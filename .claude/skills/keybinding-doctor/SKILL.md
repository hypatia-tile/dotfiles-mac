---
name: keybinding-doctor
description: Diagnose why a macOS key or chord does not produce its expected output (swallowed, wrong char, fires a command) — locate the intercepting layer and name where the declarative fix lives. Use when the owner reports a key that "doesn't work", is "blocked", or behaves unexpectedly system-wide or in one app.
---

# keybinding-doctor

Find what intercepts a macOS key/chord and where to fix it. Ordered from the
most common, cheapest checks to the rarest. **Read-only diagnosis** — do not
change config or activate anything; end by naming the culprit and the fix
location for the owner to decide.

## Principles (learned the hard way)

- **Verify empirically, never by inference.** Do not declare a tool "not
  running" or a layer "fine" from one check. Process names are **case-sensitive**
  — the AeroSpace process is `AeroSpace`, not `aerospace`; use `pgrep -i` and
  full process lists.
- **Chase the asymmetry.** If `Option+.` works but `Option+,` does not, it is a
  *per-chord binding*, not a modifier/layout-wide problem. Let that narrow the
  search.
- **Prefer a decisive test** (`aerospace config --get …`, quit-app-and-retest,
  or asking the owner for the *exact* observed output) over theorising.

## Step 0 — Characterise the symptom

Get from the owner, precisely:

- the exact chord (e.g. `Option+,`);
- expected vs actual: nothing / a different char / a command fired;
- **where**: one app, or everywhere including **Spotlight/TextEdit** (a plain
  Cocoa text field). Global ⇒ a system/global layer (Steps 1–5). Single-app ⇒
  jump to Step 6.

## Step 1 — Running key interceptors (most common)

- **AeroSpace**: `pgrep -i aerospace`. If up, query the live binding:
  `aerospace config --get mode.main.binding.<chord>` (chord names: `alt-comma`,
  `alt-slash`, `alt-period`, `alt-tab`, …). Fix lives in
  `config/aerospace/aerospace.toml` (in scope).
- **Hammerspoon**: `pgrep -i hammerspoon`; inspect `~/.hammerspoon/` for
  `hs.hotkey.bind`/`hs.eventtap` on the chord (config from `config/hammerspoon/`).
- **Karabiner**: `pgrep -i karabiner`; `~/.config/karabiner/karabiner.json`.
- **Others**: yabai, skhd, BetterTouchTool, Raycast, Alfred.
- **Menu-bar / agent apps** register global hotkeys via `RegisterEventHotKey`,
  invisible to `defaults`. List them:
  `osascript -e 'tell application "System Events" to get name of every process whose background only is true'`
  and foreground apps (`… background only is false`). Common grabbers: Discord
  (push-to-talk / keybinds), Slack (global shortcut). **Decisive test:** quit
  the suspect app and re-test the chord. Fix is that app's settings (out of
  repo scope).

## Step 2 — macOS system shortcuts (defaults)

- `defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys` — look for an
  entry whose `value.parameters` match the chord's keycode + modifier mask
  (managed here in `modules/darwin/macos.nix`; comma keycode = 43,
  Option mask = 524288).
- App menu shortcuts: `defaults read -g NSUserKeyEquivalents` and per-app
  domains.
- Services: `defaults read pbs`.

## Step 3 — Cocoa text key-binding layer (AppKit)

Affects **all** Cocoa text fields (Spotlight, TextEdit, Safari, Mail) but not
non-Cocoa apps or Emacs. A `noop:`/action mapping on the chord swallows it.

- `~/Library/KeyBindings/DefaultKeyBinding.dict`,
  `/Library/KeyBindings/DefaultKeyBinding.dict`,
  `/Network/Library/KeyBindings/…`.

## Step 4 — HID / modifier remap (lowest level)

- `hidutil property --get "UserKeyMapping"`; any nix-darwin
  `system.keyboard.userKeyMapping`; modifier remaps in `-g`.

## Step 5 — Keyboard layout / input source

- `defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleCurrentKeyboardLayoutInputSourceID`
- custom layouts in `~/Library/Keyboard Layouts`.
- Dead keys (on `ABC`: `Option+e/i/u/n/\``) emit nothing until the next key —
  not a bug.

## Step 6 — App-internal handling (single-app symptoms)

- **Emacs (GUI)**: `mac-option-modifier = meta` (default in emacs-plus) means
  Option is **Meta**, so `Option+,` is `M-,` (a command), *not* char input —
  expected, not a fault. Emacs config is out of scope (ADR 0002).
- **Terminals**: kitty `macos_option_as_alt`, alacritty `option_as_alt`
  (in scope: `config/kitty/`, `config/alacritty/`).
- **Browser**: extensions (Vimium/Tridactyl) — affect that browser only, so
  never the cause of a Spotlight-visible symptom.

## Report

State: (1) the culprit and which layer, (2) the fix location and whether it is
**in repo scope** (`aerospace.toml`, `macos.nix`, `kitty.conf`,
`alacritty.toml`) or **out of scope** (Emacs init per ADR 0002, third-party app
settings), and (3) the concrete one-line change. Do not apply it here — the
owner decides and drives the change through the normal workflow.
