{
  description = "macOS configuration: nix-darwin + Home Manager in a single flake";

  inputs = {
    # What is installed and at which version: Nix packages, Homebrew, fonts,
    # and the overlays they need (ADR 0037). This flake takes nixpkgs from it,
    # so a new package set arrives by moving this input in its own commit
    # (ADR 0011). nix-darwin and Home Manager are its inputs only for its own
    # checks; they follow this flake's, so the lock carries one of each.
    nix-packages = {
      url = "github:hypatia-tile/nix-packages";
      inputs.nix-darwin.follows = "nix-darwin";
      inputs.home-manager.follows = "home-manager";
    };
    nixpkgs.follows = "nix-packages/nixpkgs";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-packages,
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
              # Homebrew, fonts and the overlays (neovim-nightly, rust,
              # emacs-flake, in that order). The Home Manager side,
              # home.packages, is imported by modules/home.
              nix-packages.darwinModules.default
              home-manager.darwinModules.home-manager
              {
                nixpkgs.hostPlatform = host.system;
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
          # The overlay the hosts apply, so the Neovim checked is the one the
          # machine runs: on the machine it is the same store path. No cache
          # carries it for this nixpkgs, so CI builds it once per lock.
          nvimPkgs = pkgs.extend nix-packages.inputs.neovim-nightly-overlay.overlays.default;
        in
        rec {
          # The nvim checks' shell: the startup check and LuaLS need the
          # editor itself, and denops needs Deno at startup. Kept apart so the
          # other gates never wait on a Neovim build.
          nvim = pkgs.mkShellNoCC {
            inputsFrom = [ default ];
            packages = [
              nvimPkgs.neovim
              pkgs.deno
            ];
          };

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
