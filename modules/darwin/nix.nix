{
  # Nix is installed via the Determinate installer, which manages its own
  # daemon; nix-darwin must not own /etc/nix/nix.conf. The effective user
  # configuration is the HM-managed ~/.config/nix/nix.conf (flake-design §4).
  nix.enable = false;

  # Required for unfree packages (proprietary fonts, etc.).
  nixpkgs.config.allowUnfree = true;
}
