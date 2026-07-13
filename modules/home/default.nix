# User layer aggregator — everything user-facing lives here (ADR 0006).
# files.nix (dotfile placement) joins in implementation phase 2 (flake-design §6).
{
  imports = [
    ./base.nix
    ./packages.nix
    ./programs.nix
  ];
}
