# System layer aggregator — system-required settings only (ADR 0006).
{
  imports = [
    ./nix.nix
    ./users.nix
    ./fonts.nix
    ./homebrew.nix
    ./macos.nix
  ];
}
