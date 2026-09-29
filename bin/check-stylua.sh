#!/usr/bin/env bash
# The nvim payload's Lua is formatted as config/nvim/.stylua.toml says, with
# the stylua the check devShell pins (ADR 0032). A change to that file checks
# everything.
#
# Usage: nix develop -c bin/check-stylua.sh [--applies] [FILE...]
#        (the contract is in bin/lib/check.sh)
# Fix:   nix develop -c stylua --config-path config/nvim/.stylua.toml <file>...
set -euo pipefail
# shellcheck source=lib/check.sh source-path=SCRIPTDIR
. "$(dirname "$0")/lib/check.sh"

CONFIG=config/nvim/.stylua.toml

scope 'config/nvim/*.lua' "$CONFIG"

run_check() {
  local files=() f
  need stylua
  for f in "$@"; do
    case $f in
      "$CONFIG") CHECK_ALL=true ;;
      *) files+=("$f") ;;
    esac
  done
  if $CHECK_ALL; then
    mapfile -t files < <(tracked_files 'config/nvim/*.lua')
  fi
  if [[ ${#files[@]} -gt 0 ]]; then
    step stylua stylua --check --config-path "$CONFIG" "${files[@]}"
  fi
}

check_main "$@"
