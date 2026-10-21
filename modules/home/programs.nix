{
  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # zsh, git, tmux, kitty, alacritty, helix, etc. are shipped as plain
    # files by payloads/ (ADR 0020, ADR 0034), not as HM program modules.

    # Home Manager enables man-db by default, and it shadows /usr/bin/man.
    # Only Apple's man adds `xcode-select --show-manpaths`, where the SDK's
    # sections 2 and 3 live; it still finds Nix packages' pages via PATH (#279).
    man.enable = false;

    home-manager.enable = true;
  };
}
