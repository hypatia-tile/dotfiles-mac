# Identity constants shared across darwin and Home Manager modules. For a new
# machine's user, `username` is the one line to change; the paths follow it.
# The machine's name lives in hosts/*.nix (#340).
rec {
  username = "kazukishinohara";
  homeDirectory = "/Users/${username}";

  # Absolute path to this checkout. Config payloads are placed from here as
  # working-tree symlinks (ADR 0021, ADR 0034), so the machine's configuration
  # depends on the repository living at this path: move it and the links
  # dangle.
  checkoutPath = "${homeDirectory}/ghqrepo/github.com/hypatia-tile/dotfiles-mac";
}
