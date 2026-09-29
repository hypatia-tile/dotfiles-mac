#!/usr/bin/env bash
# The flake evaluates and every host's system closure builds, against the
# locked inputs: `nix flake check`, then `nix build` of each
# darwinConfigurations entry. Build only; nothing is switched or activated
# (ADR 0003).
#
# Only Nix files and the lock can change what the flake evaluates to: no module
# reads another file into the store, and since ADR 0021 a payload under config/
# is placed by path, so editing one leaves the closure byte-identical.
#
# The closures are aarch64-darwin, so this runs on macOS only. It needs nothing
# from the check devShell beyond nix itself. The builds leave no ./result:
# preflight builds its own link for the closure diff.
#
# Usage: bin/check-flake.sh [--applies] [FILE...]
#        (the contract is in bin/lib/check.sh; FILE only decides whether the
#        whole check runs)
set -euo pipefail
# shellcheck source=lib/check.sh source-path=SCRIPTDIR
. "$(dirname "$0")/lib/check.sh"

scope '*.nix' flake.lock
check_gate "$@"

need nix
if [[ $(uname -s) != Darwin ]]; then
  echo "$(basename "$0"): the host closures are darwin; run this on macOS" >&2
  exit 2
fi

step 'flake check' nix flake check --no-update-lock-file -L

hosts=$(nix eval .#darwinConfigurations --no-update-lock-file --raw \
  --apply 'hs: builtins.concatStringsSep "\n" (builtins.attrNames hs)')
for host in $hosts; do
  step "build $host" nix build ".#darwinConfigurations.$host.system" \
    --no-update-lock-file --no-link -L
done

exit "$CHECK_FAILED"
