{ pkgs, ... }:
{
  # Per inventory A-9, TeX never enters the system closure (per-project
  # flakes instead); alejandra is replaced by nixfmt-rfc-style (ADR 0012).
  home.packages = with pkgs; [
    # Terminal emulators and multiplexers
    alacritty
    kitty
    tmux
    # herdr: tmux-alternative, kept alongside tmux (do not nest one in the
    # other — both use the C-q prefix). Config: config/herdr/config.toml
    # (linked file-only via files.nix). Currently 0.8.0 from the pinned nixpkgs.
    herdr

    # Shell utilities
    eza
    fd
    ripgrep
    bat
    fzf
    tree
    htop
    jq
    sqlite
    ghq
    delta

    # Git utilities
    git-filter-repo

    # Editors
    neovim
    vim
    helix

    # Development tools
    cargo
    rust-analyzer
    rustc
    deno
    gh
    lazygit
    nodejs_24
    typescript-language-server
    flutter

    # Languages
    lua5_1
    jdk21_headless

    # Package managers
    luarocks
    jdt-language-server

    # Build tools
    gradle

    # Nix tools
    nixfmt-rfc-style
    statix
    deadnix
    nil

    # Language servers
    vim-language-server
    bash-language-server
    lua-language-server

    # AI coding assistants
    copilot-language-server
    claude-code
    codex

    # zenn cli
    zenn-cli
  ];
}
