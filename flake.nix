{
  description = "macOS configuration: nix-darwin + Home Manager in a single flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Emacs, pinned and patched in its own flake (ADR 0031).
    #
    # Deliberately no `inputs.nixpkgs.follows`. That flake applies a patch, so
    # its Emacs is not in cache.nixos.org and it publishes to a cache of its
    # own, built by its CI against its own lock. Making it follow this
    # repository's nixpkgs would build a different derivation, miss that cache
    # every time, and put a twenty-minute Emacs build back on the machine.
    emacs-flake.url = "github:hypatia-tile/emacs-flake";
  };

  outputs =
    inputs@{
      nixpkgs,
      nix-darwin,
      home-manager,
      neovim-nightly-overlay,
      rust-overlay,
      emacs-flake,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      common = import ./modules/common.nix;

      # Every hosts/*.nix is a host entry ({ hostname, system, module });
      # adding a machine means adding one file here (ADR 0004).
      hosts = lib.mapAttrsToList (name: _: import (./hosts + "/${name}")) (
        lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (
          builtins.readDir ./hosts
        )
      );

      mkHost =
        host:
        lib.nameValuePair host.hostname (
          nix-darwin.lib.darwinSystem {
            specialArgs = {
              inherit inputs;
            };
            modules = [
              ./modules/darwin
              home-manager.darwinModules.home-manager
              {
                nixpkgs.hostPlatform = host.system;
                nixpkgs.overlays = [
                  neovim-nightly-overlay.overlays.default
                  rust-overlay.overlays.default
                  emacs-flake.overlays.default
                ];
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  backupFileExtension = "hm-bak";
                  extraSpecialArgs = {
                    inherit inputs;
                  };
                  users.${common.username} = import ./modules/home;
                };
              }
              host.module
            ];
          }
        );
    in
    {
      darwinConfigurations = lib.listToAttrs (map mkHost hosts);

      # The tools the verification gates run with, pinned by flake.lock
      # (ADR 0032). Hooks, preflight and CI all run inside this shell, so a
      # linter's version moves only when the lock does. x86_64-linux is the
      # Ubuntu runners.
      devShells = lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              commitlint
              deadnix
              gitleaks
              jq
              lefthook
              lua-language-server
              markdownlint-cli2
              nixfmt
              python3
              shellcheck
              statix
              stylua
              zsh
            ];
          };
        }
      );
    };
}
