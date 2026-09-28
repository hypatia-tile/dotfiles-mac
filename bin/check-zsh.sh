#!/usr/bin/env bash
# zsh payload syntax: `zsh -n` on every file the zsh payload holds, with the
# zsh the check devShell pins (ADR 0032).
#
# The check the macOS closure build never performed: the build copied these
# files, it did not parse them. shellcheck cannot cover them either — it has
# no zsh support (SC1071), which is why check-shell.sh excludes `config`.
# Everything under config/zsh is zsh, so the scope is the directory rather
# than a list a new file could be missing from.
#
# Usage: nix develop -c bin/check-zsh.sh [--applies] [FILE...]
#        (the contract is in bin/lib/check.sh)
set -euo pipefail
# shellcheck source=lib/check.sh source-path=SCRIPTDIR
. "$(dirname "$0")/lib/check.sh"

scope 'config/zsh/*' config/zshenv

run_check() {
  local files=("$@") f
  need zsh
  if $CHECK_ALL; then
    mapfile -t files < <(tracked_files config/zsh config/zshenv)
  fi
  for f in ${files[@]+"${files[@]}"}; do
    step "$f" zsh -n "$f"
  done
}

check_main "$@"
