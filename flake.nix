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
    # Neovim configuration, pinned as a non-flake input and placed by
    # Home Manager (inventory A-7, ADR 0014).
    nvim-config = {
      url = "github:hypatia-tile/nvim-config";
      flake = false;
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nix-darwin,
      home-manager,
      neovim-nightly-overlay,
      rust-overlay,
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
    };
}
