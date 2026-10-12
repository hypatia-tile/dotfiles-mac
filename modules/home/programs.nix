{
  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # zsh, git, tmux, kitty, alacritty, helix, etc. are shipped as plain
    # files by payloads/ (ADR 0020, ADR 0034), not as HM program modules.

    home-manager.enable = true;
  };
}
