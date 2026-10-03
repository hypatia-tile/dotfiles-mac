#!/usr/bin/env bash
# Shell lint with shellcheck, at the version the check devShell pins
# (ADR 0032). It reads *.sh and *.bash files, and extensionless executables
# with a shell shebang under bin/ and .githooks/, whose names Git fixes — an
# extensionless script anywhere else is not in scope, so it belongs in bin/ or
# gets an extension. config/ is
# excluded: it holds dotfile payloads, zsh among them, which shellcheck cannot
# parse (SC1071). .shellcheckrc applies to every file, so a change to it
# checks everything.
#
# Usage: nix develop -c bin/check-shell.sh [--applies] [FILE...]
#        (the contract is in bin/lib/check.sh)
set -euo pipefail
# shellcheck source=lib/check.sh source-path=SCRIPTDIR
. "$(dirname "$0")/lib/check.sh"

scope '*.sh' '*.bash' 'bin/*' '.githooks/*' .shellcheckrc
exclude 'config/*'

is_shell() {
  case $1 in
    *.sh | *.bash) return 0 ;;
    *.*) return 1 ;;
  esac
  [[ -x $1 ]] && head -n 1 "$1" | grep -Eq '^#!.*[/ ](ba|da|k)?sh([[:space:]]|$)'
}

run_check() {
  local candidates=("$@") files=() f
  need shellcheck
  if $CHECK_ALL || [[ " $* " == *" .shellcheckrc "* ]]; then
    mapfile -t candidates < <(tracked_files '*')
  fi
  for f in ${candidates[@]+"${candidates[@]}"}; do
    is_shell "$f" && files+=("$f")
  done
  if [[ ${#files[@]} -gt 0 ]]; then
    step shellcheck shellcheck "${files[@]}"
  fi
}

check_main "$@"
