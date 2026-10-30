# User layer aggregator — everything user-facing lives here (ADR 0006).
# home.packages comes from nix-packages (ADR 0037): the shared list, and the
# macOS-only one, which puts itself first.
{ inputs, ... }:
let
  common = import ../common.nix;
in
{
  imports = [
    ./base.nix
    inputs.nix-packages.homeModules.shared
    inputs.nix-packages.homeModules.darwin
    ./programs.nix
    ./payloads/shared.nix
    ./payloads/darwin.nix
  ];

  payloads.checkoutPath = common.checkoutPath;
}
