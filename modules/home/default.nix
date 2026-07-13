# User layer aggregator — everything user-facing lives here (ADR 0006).
{
  imports = [
    ./base.nix
    ./packages.nix
    ./programs.nix
    ./files.nix
  ];
}
