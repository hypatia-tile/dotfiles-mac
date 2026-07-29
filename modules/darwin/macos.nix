# Declarative macOS keybindings — Layer 1 (system shortcuts) only.
#
# Scope is deliberately narrow (keybindings-only, see ADR 0017 and
# docs/discovery/keybindings-inventory.md); the dock/finder/NSGlobalDomain
# toggles in docs/discovery/macos-defaults-snapshot.md stay deferred.
#
# These are user-domain preference-plumbing keys, placed in the nix-darwin
# system layer as a deliberate narrow exception to ADR 0006 (they are not
# user "dotfiles"; system.defaults is the idiomatic home). Applied at system
# activation; com.apple.symbolichotkeys additionally needs a logout or
# `activateSettings -u` to take visible effect — see the keybinding checklist
# in docs/operations.md.
#
# IMPORTANT: nix-darwin writes this as
#   defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys '<whole dict>'
# which REPLACES the entire AppleSymbolicHotKeys dictionary — it does not merge.
# Therefore the dict below must be the COMPLETE set: any ID omitted would revert
# to its macOS built-in default on activation, so every ID is declared even
# though all are now off.
#
# Per the owner decision of 2026-07-29 (keybindings-inventory.md Layer 1), ALL
# of these shortcuts are disabled (enabled = 0) — including the formerly-enabled
# Mission Control family (32/33/34/36/37) and native Space switching (79-82).
# Disabling 32/33/36 only drops the legacy Fn+F9/F8/F7 bindings; Mission Control
# stays reachable via the F3 feature key and the trackpad gesture. `value`
# blocks are retained only to document which key each ID would otherwise use.
{
  system.defaults.CustomUserPreferences."com.apple.symbolichotkeys" = {
    AppleSymbolicHotKeys = {
      ## ---- disabled: pinned off (the goal) ----

      # Accessibility: Zoom / Invert / Contrast / smoothing (15-26).
      "15" = {
        enabled = 0;
      };
      "16" = {
        enabled = 0;
      };
      "17" = {
        enabled = 0;
      };
      "18" = {
        enabled = 0;
      };
      "19" = {
        enabled = 0;
      };
      "20" = {
        enabled = 0;
      };
      "21" = {
        enabled = 0;
      };
      "22" = {
        enabled = 0;
      };
      "23" = {
        enabled = 0;
      };
      "24" = {
        enabled = 0;
      };
      "25" = {
        enabled = 0;
      };
      "26" = {
        enabled = 0;
      };

      # Accessibility-adjacent / focus movement (44-49).
      "44" = {
        enabled = 0;
      };
      "45" = {
        enabled = 0;
      };
      "46" = {
        enabled = 0;
      };
      "48" = {
        enabled = 0;
      };
      "49" = {
        enabled = 0;
      };

      # Input-source switching — frees Ctrl+Space / Ctrl+Opt+Space for editors.
      "60" = {
        enabled = 0;
        value = {
          parameters = [
            32
            49
            262144
          ];
          type = "standard";
        };
      };
      "61" = {
        enabled = 0;
        value = {
          parameters = [
            32
            49
            786432
          ];
          type = "standard";
        };
      };

      # Newer system shortcut (no key assigned).
      "164" = {
        enabled = 0;
        value = {
          parameters = [
            65535
            65535
            0
          ];
          type = "standard";
        };
      };

      ## ---- formerly enabled, disabled by owner decision (2026-07-29) ----

      # Mission Control family on legacy F-keys.
      "32" = {
        enabled = 0;
        value = {
          parameters = [
            65535
            101
            0
          ]; # F9 — Mission Control (All Windows)
          type = "standard";
        };
      };
      "33" = {
        enabled = 0;
        value = {
          parameters = [
            65535
            100
            0
          ]; # F8 — Application Windows
          type = "standard";
        };
      };
      "34" = {
        enabled = 0;
        value = {
          parameters = [
            65535
            100
            131072
          ]; # Shift+F8 — All Windows (slow)
          type = "standard";
        };
      };
      "36" = {
        enabled = 0;
        value = {
          parameters = [
            65535
            98
            0
          ]; # F7 — Show Desktop
          type = "standard";
        };
      };
      "37" = {
        enabled = 0;
        value = {
          parameters = [
            65535
            98
            131072
          ]; # Shift+F7 — Show Desktop (slow)
          type = "standard";
        };
      };

      # Native Space switching (Ctrl+Arrow) — redundant with aerospace; disabled
      # to free Ctrl+Left/Right for terminal/editor word motion.
      "79" = {
        enabled = 0;
      };
      "80" = {
        enabled = 0;
      };
      "81" = {
        enabled = 0;
      };
      "82" = {
        enabled = 0;
      };
    };
  };
}
