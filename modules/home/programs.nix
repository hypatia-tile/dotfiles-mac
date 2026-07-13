{
  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # zsh, git, tmux, kitty, alacritty, helix, etc. are shipped as plain
    # files by files.nix (phase 2), not as HM program modules.

    home-manager.enable = true;
  };
}
