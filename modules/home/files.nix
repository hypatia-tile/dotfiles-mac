{ inputs, pkgs, ... }:
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

    # herdr: standalone trial as a tmux alternative. Only config.toml is linked,
    # not the whole directory: herdr writes runtime state (sockets, logs,
    # session.json, .plugins.lock) into ~/.config/herdr, so the directory must
    # stay writable — same reasoning as the zsh ZDOTDIR case above. Dormant until
    # cutover; the trial runs herdr via `nix run nixpkgs#herdr` against a
    # hand-placed ~/.config/herdr/config.toml (backed up as .hm-bak on cutover).
    "herdr/config.toml".source = ../../config/herdr/config.toml;

    # Effective Nix configuration: with nix.enable = false (Determinate
    # installer) the nix-darwin nix.settings module is inert, so the user
    # nix.conf is managed here instead (flake-design §4 note 2).
    "nix".source = ../../config/nix;

    # Neovim configuration comes from the pinned non-flake input; editing it
    # means pushing to hypatia-tile/nvim-config and bumping the pin.
    "nvim".source = inputs.nvim-config;
  };

  # SKK L dictionary for skkeleton in Neovim (inventory C-6: provided from
  # nixpkgs instead of vendoring). The nvim config reads it from
  # ~/.local/share/skk; the writable user dictionary lives in nvim's own
  # data dir and is not managed here.
  xdg.dataFile."skk/SKK-JISYO.L".source = "${pkgs.skkDictionaries.l}/share/skk/SKK-JISYO.L";
}
