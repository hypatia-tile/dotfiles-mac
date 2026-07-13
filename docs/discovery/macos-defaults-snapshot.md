# macOS defaults snapshot

Curated snapshot taken 2026-07-13 on `Kazukis-MacBook-Air` (macOS 26.5.1).
Input for the future `system.defaults` adoption phase (ADR 0002); only
settings-relevant keys were read — no MRU lists, no file paths.
`<unset>` means the key is at the OS default.

## com.apple.dock

| Key | Value |
|---|---|
| autohide | 1 |
| tilesize | 28 |
| orientation | left |
| mru-spaces | `<unset>` |
| show-recents | 0 |
| autohide-delay | `<unset>` |

## com.apple.finder

| Key | Value |
|---|---|
| AppleShowAllFiles | `<unset>` |
| ShowPathbar | `<unset>` |
| ShowStatusBar | `<unset>` |
| FXPreferredViewStyle | Nlsv (list view) |
| AppleShowAllExtensions | `<unset>` |

## NSGlobalDomain

| Key | Value |
|---|---|
| KeyRepeat | `<unset>` |
| InitialKeyRepeat | `<unset>` |
| ApplePressAndHoldEnabled | 0 |
| AppleInterfaceStyle | Dark |
| AppleShowAllExtensions | 1 |
| NSAutomaticSpellingCorrectionEnabled | `<unset>` |
| NSAutomaticCapitalizationEnabled | 1 |

Candidates worth declaring later: dock autohide/size/orientation,
show-recents, ApplePressAndHoldEnabled (vim-style key repeat),
AppleInterfaceStyle, AppleShowAllExtensions.
