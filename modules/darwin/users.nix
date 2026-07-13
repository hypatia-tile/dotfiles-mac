let
  common = import ../common.nix;
in
{
  # Enable zsh system-wide (required for the user's login shell).
  programs.zsh.enable = true;

  system.primaryUser = common.username;

  users.users.${common.username} = {
    home = common.homeDirectory;
  };
}
