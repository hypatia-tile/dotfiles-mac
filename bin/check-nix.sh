#!/usr/bin/env bash
# Nix format and lint: nixfmt, deadnix and statix, at the versions the check
# devShell pins (ADR 0032).
#
# nixfmt and deadnix read the files they are given. statix runs over the
# whole tree whenever any Nix file is in scope, since its findings are not
# confined to the file that changed.
#
# Usage: nix develop -c bin/check-nix.sh [--applies] [FILE...]
#        (the contract is in bin/lib/check.sh)
# Fix:   nix develop -c nixfmt <file>...
set -euo pipefail
# shellcheck source=lib/check.sh source-path=SCRIPTDIR
. "$(dirname "$0")/lib/check.sh"

scope '*.nix'

run_check() {
  local files=("$@")
  need nixfmt deadnix statix
  if $CHECK_ALL; then
    mapfile -t files < <(tracked_files '*.nix')
  fi
  if [[ ${#files[@]} -gt 0 ]]; then
    step nixfmt nixfmt --check "${files[@]}"
    step deadnix deadnix --fail "${files[@]}"
  fi
  step statix statix check .
}

check_main "$@"
