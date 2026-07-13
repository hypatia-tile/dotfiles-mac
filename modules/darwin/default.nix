# System layer aggregator — system-required settings only (ADR 0006).
# homebrew.nix joins in implementation phase 3 (flake-design §6).
{
  imports = [
    ./nix.nix
    ./users.nix
    ./fonts.nix
    ./macos.nix
  ];
}
