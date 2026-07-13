{ inputs, ... }:
{
  home.file = {
    # ZDOTDIR bootstrap — the whole zsh setup depends on it (inventory A-14).
    ".zshenv".source = ../../config/zshenv;
    ".hammerspoon".source = ../../config/hammerspoon;
  };

  xdg.configFile = {
    # zsh is linked file-by-file (recursive), not as one directory symlink:
    # HISTFILE and .zcompdump live inside ZDOTDIR, so the directory itself
    # must stay writable.
    "zsh" = {
      source = ../../config/zsh;
      recursive = true;
    };

    "git".source = ../../config/git;
    "tmux".source = ../../config/tmux;
    "kitty".source = ../../config/kitty;
    "alacritty".source = ../../config/alacritty;
    "aerospace".source = ../../config/aerospace;
    "lazygit".source = ../../config/lazygit;

    # Effective Nix configuration: with nix.enable = false (Determinate
    # installer) the nix-darwin nix.settings module is inert, so the user
    # nix.conf is managed here instead (flake-design §4 note 2).
    "nix".source = ../../config/nix;

    # Neovim configuration comes from the pinned non-flake input; editing it
    # means pushing to hypatia-tile/nvim-config and bumping the pin.
    "nvim".source = inputs.nvim-config;
  };
}
