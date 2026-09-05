# Identity constants shared across darwin and Home Manager modules.
{
  username = "kazukishinohara";
  homeDirectory = "/Users/kazukishinohara";

  # Absolute path to this checkout. Config payloads are placed from here as
  # working-tree symlinks (ADR 0021), so the machine's configuration depends
  # on the repository living at this path: move it and the links dangle.
  checkoutPath = "/Users/kazukishinohara/ghqrepo/github.com/hypatia-tile/dotfiles-mac";

  gitUserName = "shinokun";
  gitUserEmail = "hypatia.tile02021@gmail.com";
}
