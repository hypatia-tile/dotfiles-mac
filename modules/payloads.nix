# Payloads projected into $HOME by bin/project.sh (ADR 0026).
#
# Plain data, deliberately outside modules/home/files.nix: a payload declared
# there is *placed* by Home Manager, and there is no declare-without-placing.
# Keeping the two lists disjoint is what stops a path acquiring two owners —
# the constraint ADR 0001 was written to establish, and the reason a partition
# works where "retire files.nix entirely" never could.
#
# Read with `nix eval -f`, which costs 0.15s and needs neither the flake nor
# Home Manager.
#
# A payload the projector itself depends on cannot be listed here. ~/.config/nix
# is the case that proved it: `nix eval` needs the experimental features the
# user nix.conf enables, so projecting it made the projector unable to read this
# file — and the failure lands exactly when Home Manager has already released
# the path. bin/project.sh refuses such entries; see SELF_DEPENDENCIES there.
#
#   <target relative to $HOME> = {
#     source = <path relative to the checkout>;
#     mode   = "copy" | "link";
#   };
#
# `copy` is a read-only copy and is the default disposition: it is what makes
# ~/.config a projection rather than an editing surface.
#
# `link` is a symlink to the working tree, for the case a copy cannot serve —
# a file the tool must write *back into the repository*. A writable copy is not
# an option there, because it diverges from the repository instead of updating
# it. Declare `link` per path, never per payload, so that each exception stays
# visible.
{
  ".config/git" = {
    source = "config/git";
    mode = "copy";
  };
  ".config/tmux" = {
    source = "config/tmux";
    mode = "copy";
  };
  ".config/kitty" = {
    source = "config/kitty";
    mode = "copy";
  };
  ".config/alacritty" = {
    source = "config/alacritty";
    mode = "copy";
  };
  ".config/aerospace" = {
    source = "config/aerospace";
    mode = "copy";
  };
  ".config/lazygit" = {
    source = "config/lazygit";
    mode = "copy";
  };
  # Not under ~/.config: Hammerspoon reads ~/.hammerspoon, and the launchd
  # agent in modules/home/base.nix starts the app that reads it.
  ".hammerspoon" = {
    source = "config/hammerspoon";
    mode = "copy";
  };

  # herdr writes logs, session.json, sessions/ and .plugins.lock into its
  # config directory, so only the file this repository owns is projected —
  # the same reasoning that kept it a single-file link under ADR 0021.
  ".config/herdr/config.toml" = {
    source = "config/herdr/config.toml";
    mode = "copy";
  };
}
