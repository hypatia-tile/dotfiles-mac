# macOS keybinding inventory

> **Historical record — the survey behind ADR 0017.** The declarative
> keybinding phase it fed is complete (#27, #29), so the per-row proposals and
> verdicts are spent and the observed values date from 2026-07-29. **One part
> is still current:** the four-layer table below — which mechanism owns which
> kind of shortcut, and where each is declared — remains the reference for
> where a keybinding fix belongs, and the `keybinding-doctor` skill applies
> it. Kept in place because ADR 0017 references this file by path (ADR 0019).

Read-only discovery of macOS default key behavior, taken 2026-07-29 on
`Kazukis-MacBook-Air`. Input for the declarative keybinding-management phase
(its own ADR, per ADR 0002). Scope is **keybindings only**; the dock/finder/
NSGlobalDomain toggles remain deferred (see `macos-defaults-snapshot.md`).

Four independent layers were surveyed. Each has a different declarative
mechanism and placement:

| Layer | Mechanism | Placement |
|---|---|---|
| System shortcuts | `com.apple.symbolichotkeys` (`AppleSymbolicHotKeys`) | nix-darwin `system.defaults.CustomUserPreferences` |
| App menu shortcuts | `NSUserKeyEquivalents` (per-app / global) | nix-darwin `system.defaults` |
| Text-field editing | `~/Library/KeyBindings/DefaultKeyBinding.dict` | Home Manager `home.file` |
| Option special chars | Karabiner-Elements `karabiner.json` | HM `home.file` + cask in `homebrew` module |

**Verdict legend:** `declare-off` = pin the existing disabled state
declaratively; `declare-on` = pin the existing enabled state; `keep` = leave
enabled, do not declare; `disable?` = candidate for disabling, owner decides;
`remap` = change the key. The **Verdict** column is my *proposal* — edit it,
then only approved rows are implemented.

---

## Layer 1 — System shortcuts (`com.apple.symbolichotkeys`)

Raw state read via `defaults read com.apple.symbolichotkeys`. Most entries are
**already disabled imperatively** — the declarative value here is capturing
that curation so it survives a rebuild / a new machine, not discovering new
things to turn off. ID→feature names sourced from community mappings
(diimdeep/dotfiles, andyjakubowski/dotfiles); IDs marked `?` are inferred with
lower confidence.

> **Mechanism finding (2026-07-29):** nix-darwin writes this as
> `defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys '<whole dict>'`,
> which **replaces the entire dictionary** — it does not merge. So the declared
> dict must be the *complete* set, or any omitted ID reverts to its macOS
> built-in default on activation. The first pass pinned the still-enabled IDs
> verbatim; a follow-up owner decision (2026-07-29) then disabled them too, so
> every ID is now declared with `enabled = 0`.
>
> **Status:** implemented in `modules/darwin/macos.nix` (Layer 1 only). All 29
> IDs disabled per owner decision. Build-only verified. Layers 2–4 held.

### Already disabled (`enabled = 0`) — captured as `declare-off` ✅ implemented

| ID | Feature | Current | Verdict | Notes |
|---|---|---|---|---|
| 15 | Accessibility: Zoom on/off | off | declare-off | |
| 16 | Accessibility: Zoom (focus follows) ? | off | declare-off | |
| 17 | Accessibility: Zoom in | off | declare-off | |
| 18 | Accessibility: Zoom (paired) ? | off | declare-off | |
| 19 | Accessibility: Zoom out | off | declare-off | |
| 20 | Accessibility: Zoom (paired) ? | off | declare-off | |
| 21 | Accessibility: Invert colors | off | declare-off | |
| 22 | Accessibility: Image smoothing ? | off | declare-off | |
| 23 | Accessibility: Image smoothing | off | declare-off | |
| 24 | Accessibility: Contrast (paired) ? | off | declare-off | |
| 25 | Accessibility: Increase contrast | off | declare-off | |
| 26 | Accessibility: Decrease contrast | off | declare-off | |
| 44 | Accessibility-adjacent ? | off | declare-off | uncertain name |
| 45 | Accessibility-adjacent ? | off | declare-off | uncertain name |
| 46 | Accessibility-adjacent ? | off | declare-off | uncertain name |
| 48 | Move focus / rotate windows ? | off | declare-off | uncertain name |
| 49 | Move focus / rotate windows ? | off | declare-off | uncertain name |
| 60 | Select **previous** input source (⌃Space) | off | declare-off | frees ⌃Space; good for editors |
| 61 | Select **next** input source (⌃⌥Space) | off | declare-off | |
| 164 | Newer feature ? (value = no key) | off | declare-off | uncertain name |

### Formerly enabled — now disabled by owner decision (2026-07-29)

All nine were pinned verbatim in the first pass; the owner then chose to disable
the lot, so `macos.nix` now sets `enabled = 0` for every ID (whole set off).

| ID | Feature | Key | Verdict | Rationale |
|---|---|---|---|---|
| 32 | Mission Control (All Windows) | Fn+F9 | disable | legacy F-key binding; Mission Control still on F3 / trackpad |
| 33 | Application Windows (App Exposé) | Fn+F8 | disable | legacy F-key binding, redundant |
| 34 | All Windows (slow) | ⇧Fn+F8 | disable | slow-motion novelty variant |
| 36 | Show Desktop | Fn+F7 | disable | legacy F-key binding |
| 37 | Show Desktop (slow) | ⇧Fn+F7 | disable | slow-motion novelty variant |
| 79 | Move left a space | ⌃← | disable | redundant with aerospace; frees ⌃← |
| 80 | Move left a space (paired) | ⌃← | disable | " |
| 81 | Move right a space | ⌃→ | disable | redundant with aerospace; frees ⌃→ |
| 82 | Move right a space (paired) | ⌃→ | disable | " |

> **Note:** disabling 32/33/36 only drops the Fn+F-key bindings — Mission
> Control, App Windows, and Show Desktop remain reachable via the F3 feature key
> and trackpad gestures. Disabling 79–82 frees ⌃←/⌃→; only relevant if native
> macOS Spaces are also used (aerospace owns workspaces here).

---

## Layer 2 — App menu shortcuts (`NSUserKeyEquivalents`)

Current global overrides: **none** (`defaults read -g NSUserKeyEquivalents`
→ unset). This layer cannot be auto-enumerated (built-in menu `⌘`-combos live
in each app's nib, not in `defaults`), and `NSUserKeyEquivalents` can only
*reassign* a menu item, not cleanly delete its default (disabling means mapping
to a throwaway combo).

**Input required from owner:** a list of concrete targets, each as
`app bundle/domain + exact menu-item title + desired shortcut (or "disable")`.
Until supplied, the mechanism is wired but this layer stays empty.

| App (domain) | Menu item title | Desired | Verdict |
|---|---|---|---|
| *(awaiting owner targets)* | | | |

---

## Layer 3 — Text-field editing (`DefaultKeyBinding.dict`)

Current state: **no `~/Library/KeyBindings/` directory exists** — the system
uses the built-in `StandardKeyBinding` set (Emacs-style ⌃A/⌃E/⌃K, ⌥← / ⌥→
word motion, etc.). Managing this layer means *creating* a new dict; "disabling"
a built-in binding = mapping that key to `noop:`.

**Input required from owner:** which built-in text bindings to disable/override
(e.g. neutralize ⌥← / ⌥→, or add custom motions). No enumeration needed — this
is a documented standard set. Proposal: leave empty unless you name specific
bindings that annoy you.

| Key | Built-in action | Desired | Verdict |
|---|---|---|---|
| *(awaiting owner targets)* | | | |

---

## Layer 4 — Option special characters — RESOLVED via aerospace (2026-07-30)

Originally scoped for Karabiner-Elements to neutralize Option-as-character-input.
The real investigation of the reported "`Option+,` cannot be typed anywhere"
found a different, in-scope cause — **not a keyboard layer at all**:

- Symptom: `Option+.` produced `≥`, but `Option+,` produced nothing, even in
  Spotlight (a Cocoa text field). Ruled out: layout (standard `ABC`),
  `DefaultKeyBinding.dict` (absent), symbolichotkeys / NSUserKeyEquivalents /
  Services / HID remap (none), Discord/Slack global keybinds (quit-tested, not
  the cause).
- **Cause: AeroSpace was running and binds `alt-comma` → `layout accordion`**
  (`aerospace config --get mode.main.binding.alt-comma` confirmed live). Its
  bindings are global, so it swallowed `Option+,` in every app — including
  Emacs, so `M-,` never reached Emacs either. `Option+.` was free because
  aerospace binds no `alt-period`. (Initial "aerospace not running" check was a
  false negative: process is `AeroSpace`, not `aerospace`.)
- **Fix (in scope):** removed the `alt-comma` binding from
  `config/aerospace/aerospace.toml` (owner does not use the accordion toggle).
  `Option+,` now passes through: `M-,` in Emacs, `≤` elsewhere.

Karabiner remains **not installed** — it was never the right tool here. On the
Emacs side, GUI Emacs.app already treats Option as Meta by default (verified
`mac-option-modifier = meta`), so nothing is needed there (and Emacs config is
out of scope, ADR 0002). Sibling aerospace binds `alt-slash` (Option+/) and
`alt-tab` (Option+Tab) are left as-is; revisit only if they also get in the way.

---

## Summary of what starts where

- **Layer 1** is fully implemented: all 29 `AppleSymbolicHotKeys` IDs declared
  `enabled = 0` — the 20 already-off IDs pinned, plus the 9 formerly-enabled
  IDs disabled by owner decision (2026-07-29).
- **Layer 4** is resolved by removing aerospace's `alt-comma` binding — the real
  blocker of `Option+,`; Karabiner was dropped as unnecessary (2026-07-30).
- **Layers 2–3** are empty today; each needs an explicit owner target list
  before implementation (mechanism will be wired regardless).
- No secrets encountered. No file contents beyond keybinding settings were read.
