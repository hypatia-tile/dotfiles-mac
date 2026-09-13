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
    # zsh abbreviation plugin, sourced by config/zsh/modules/abbr.zsh from
    # the per-user profile. nixpkgs marks it unfree (CC-BY-NC-SA-4.0 and
    # HL3), which allowUnfree in modules/darwin/nix.nix already covers; the
    # licence is the upstream project's and applied equally to the Homebrew
    # build this replaces.
    zsh-abbr

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

    # Containers. Docker Desktop is deliberately not used here: colima runs
    # the daemon inside its own Lima VM, needs no privileged helper, and is a
    # plain CLI tool, so it belongs in this layer rather than in a cask.
    #
    # lima and qemu are NOT declared alongside it. The nixpkgs colima wrapper
    # already puts lima-full, qemu, docker and krunkit on colima's own PATH;
    # declaring them again would only add a second copy to the profile.
    #
    # colima keeps its instance state and its generated colima.yaml under
    # ~/.colima, so none of it is projected — the granularity rule in
    # modules/payloads.tsv is what forbids handing that directory over.
    colima
    # The client only, on darwin: nixpkgs defaults clientOnly to !isLinux, so
    # this brings no dockerd — colima's VM provides it. buildxSupport and
    # composeSupport both default to true, so `docker buildx` and
    # `docker compose` arrive with this entry through DOCKER_CLI_PLUGIN_DIRS;
    # docker-buildx and docker-compose must not be declared separately.
    docker

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
    # Cursor's terminal agent (the `cursor-agent` binary), on trial. The GUI
    # editor is a separate package (code-cursor) and is deliberately not
    # installed. Like claude-code and codex, this moves only with flake.lock,
    # and its own `cursor-agent update` cannot write to the Nix store.
    cursor-cli
  ];
}
