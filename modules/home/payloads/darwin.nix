# Payloads only macOS has a consumer for (ADR 0034). Imported together with
# shared.nix, whose payloads.checkoutPath option this uses.
{ config, ... }:
let
  link = path: config.lib.file.mkOutOfStoreSymlink "${config.payloads.checkoutPath}/${path}";
in
{
  xdg.configFile = {
    "aerospace".source = link "config/aerospace";

    # The user nix.conf. On NixOS the system configuration owns Nix settings,
    # so this stays macOS-only.
    "nix".source = link "config/nix";
  };

  # Hammerspoon reads ~/.hammerspoon, not ~/.config; the launchd agent in
  # base.nix starts the app that reads it.
  home.file.".hammerspoon".source = link "config/hammerspoon";
}
