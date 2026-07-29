# 0017. Declarative macOS keybinding management

- Status: Accepted
- Date: 2026-07-29

## Context

macOS ships many default key behaviors the owner considers unnecessary, and the
existing curation (e.g. disabled Accessibility zoom, disabled input-source
switching) is applied imperatively and is not reproducible on a fresh machine.
ADR 0002 deferred `system.defaults` adoption to a later phase "under its own
ADR"; this is that ADR, scoped narrowly to **keybindings only** (the
dock/finder/NSGlobalDomain toggles in `docs/discovery/macos-defaults-snapshot.md`
remain deferred).

"Keybinding" spans four independent OS layers, each with a different mechanism.
A read-only survey (`docs/discovery/keybindings-inventory.md`, 2026-07-29) found
system shortcuts already heavily curated, and the other three layers empty
(no `NSUserKeyEquivalents`, no `DefaultKeyBinding.dict`, no Karabiner).

Constraints: build-only verification, never switch (ADR 0003); user-facing
config belongs in Home Manager (ADR 0006); Homebrew for casks (ADR 0005);
`flake.lock` frozen (ADR 0011).

## Decision

Manage keybindings declaratively, partitioned by layer:

| Layer | Mechanism | Placement |
|---|---|---|
| System shortcuts | `com.apple.symbolichotkeys` | nix-darwin `system.defaults.CustomUserPreferences` (`modules/darwin/macos.nix`) |
| App menu shortcuts | `NSUserKeyEquivalents` | nix-darwin `system.defaults` |
| Text-field editing | `~/Library/KeyBindings/DefaultKeyBinding.dict` | Home Manager `home.file` |
| Option special chars | Karabiner-Elements `karabiner.json` (hand-written, HM-owned) | HM `home.file` + cask in the `homebrew` module |

- The two `defaults`-based layers live in the **nix-darwin** layer as a
  deliberate, narrow **exception to ADR 0006**: user-domain preference plumbing
  is not a "dotfile", and `system.defaults` is the idiomatic, well-supported
  home. `modules/darwin/macos.nix` (previously an empty placeholder) is its home.
- Karabiner is added only for the Option-special-character layer (which no
  `defaults` key can control). Its config is a hand-written `karabiner.json`
  owned by Home Manager; the Karabiner GUI becomes effectively read-only.
- Karabiner rules must be narrowly targeted and MUST NOT swallow the Option/Alt
  chords bound by aerospace (`alt-comma`, `alt-slash`, `alt-tab`,
  `alt-shift-tab`) or Hammerspoon (`cmd-alt-*`, `cmd-alt-ctrl-*`), which it
  intercepts below.
- Which bindings are "unnecessary" is decided per-row by the owner in the
  inventory doc (ADR 0002 verdict pattern); implementation follows approved rows.
- Verification stays build-only; because a build cannot prove a keybinding is
  actually disabled on the live machine, a per-layer **manual verification
  checklist** in `docs/operations.md` is run by the owner after each switch.

### `symbolichotkeys` whole-dictionary replacement

nix-darwin writes `defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys
'<dict>'`, which **replaces the entire dictionary** rather than merging. The
declared dict must therefore be the *complete* current state: any omitted ID
reverts to its macOS built-in default on activation. Consequently the module
pins both the disabled IDs (the goal) and the still-enabled IDs (verbatim, to
avoid clobbering them) — the keep-vs-disable decision on the enabled IDs stays
open.

### Rollout

Layer 1 (`symbolichotkeys`) is implemented first
(`modules/darwin/macos.nix`, greenlit 2026-07-29): all currently-disabled IDs
pinned off, all currently-enabled IDs pinned verbatim. Layers 2–4 are agreed in
principle but **held** pending concrete owner target lists (they cannot be
auto-enumerated).

## Consequences

- The owner's existing manual shortcut curation becomes reproducible on a fresh
  machine; a rebuild no longer risks losing it.
- Placement is mixed by layer but each choice is idiomatic; the ADR 0006
  exception is explicit and bounded to preference-domain keys.
- Karabiner adds an always-running input tool plus a one-time **Input Monitoring
  TCC grant that cannot be declared** (granted manually once, like other
  first-activation dependencies) — deferred with the rest of Layer 4.
- Build proves generated plist/file *content* only, never runtime behavior;
  functional confidence depends on the manual checklist post-cutover.
- Adding the Karabiner cask does not touch `flake.lock` (casks are not Nix
  inputs), so the freeze (ADR 0011) is preserved.
- The whole-dictionary replacement of `AppleSymbolicHotKeys` means the module
  must be kept in sync if the owner later changes a shortcut via System
  Settings; drift would be silently overwritten on the next activation.
