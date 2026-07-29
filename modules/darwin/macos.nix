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
# Therefore the dict below must be the COMPLETE current state: any ID omitted
# would revert to its macOS built-in default on activation. So both groups are
# declared:
#   * "disabled" — the imperatively-curated off state we are pinning
#     (the actual goal: make it reproducible).
#   * "enabled (pinned)" — still-on shortcuts captured verbatim at their current
#     values purely to avoid clobbering them. Whether to keep or disable these
#     is still open (see keybindings-inventory.md Layer 1 "still enabled").
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

      ## ---- enabled: pinned verbatim (keep/disable still open) ----

      # Mission Control family on legacy F-keys.
      "32" = {
        enabled = 1;
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
        enabled = 1;
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
        enabled = 1;
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
        enabled = 1;
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
        enabled = 1;
        value = {
          parameters = [
            65535
            98
            131072
          ]; # Shift+F7 — Show Desktop (slow)
          type = "standard";
        };
      };

      # Native Space switching (Ctrl+Arrow) — redundant with aerospace, but no
      # key clash (aerospace uses cmd/alt). Left on for now.
      "79" = {
        enabled = 1;
      };
      "80" = {
        enabled = 1;
      };
      "81" = {
        enabled = 1;
      };
      "82" = {
        enabled = 1;
      };
    };
  };
}
