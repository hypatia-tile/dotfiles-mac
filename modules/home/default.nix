# User layer aggregator — everything user-facing lives here (ADR 0006).
let
  common = import ../common.nix;
in
{
  imports = [
    ./base.nix
    ./packages.nix
    ./programs.nix
    ./payloads/shared.nix
    ./payloads/darwin.nix
  ];

  payloads.checkoutPath = common.checkoutPath;
}
