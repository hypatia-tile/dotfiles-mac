{ pkgs, ... }:
let
  common = import ../common.nix;
in
{
  home = {
    inherit (common) username homeDirectory;
    # Set on initial configuration: 2026-01-02.
    # Do not change unless migrating or reinstalling.
    stateVersion = "25.05";

    sessionPath = [
      "${common.homeDirectory}/.nix-profile/bin"
      "/etc/profiles/per-user/${common.username}/bin"
      "/run/current-system/sw/bin"
      "/opt/homebrew/opt/llvm/bin"
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
      "/nix/var/nix/profiles/default/bin"
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ];

    sessionVariables = {
      EDITOR = "nvim";
      # Carried from the retired $HOME/.envrc (inventory A-13): the direnv
      # mechanism is excluded, only its variables survive.
      NVIM_FLOATING_MEMO_DIR = "${common.homeDirectory}/github/Memo";
      JAVA_HOME = "${pkgs.jdk21_headless.home}";
    };
  };

  xdg.enable = true;

  # Auto-start Hammerspoon at login. The app is a Homebrew cask (phase 3);
  # its configuration is placed by files.nix (phase 2).
  launchd.agents.hammerspoon = {
    enable = true;
    config = {
      ProgramArguments = [ "/Applications/Hammerspoon.app/Contents/MacOS/Hammerspoon" ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
