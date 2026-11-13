#!/usr/bin/env bash
# zsh payload syntax: `zsh -n` on every file the zsh payload holds, with the
# zsh the check devShell pins (ADR 0032).
#
# The check the macOS closure build never performed: the build copied these
# files, it did not parse them. shellcheck cannot cover them either — it has
# no zsh support (SC1071), which is why check-shell.sh excludes `config`.
# Everything under config/zsh is zsh, so the scope is the directory rather
# than a list a new file could be missing from. A change to the flake or its
# lock moves the zsh that parses them, so it checks every file too (#247), as
# check-nvim.sh does for Neovim (#153).
#
# Usage: nix develop -c bin/check-zsh.sh [--applies] [FILE...]
#        (the contract is in bin/lib/check.sh)
set -euo pipefail
# shellcheck source=lib/check.sh source-path=SCRIPTDIR
. "$(dirname "$0")/lib/check.sh"

scope 'config/zsh/*' config/zshenv flake.nix flake.lock

run_check() {
  local files=("$@") f all=$CHECK_ALL
  need zsh
  for f in ${files[@]+"${files[@]}"}; do
    case $f in flake.nix | flake.lock) all=true ;; esac
  done
  if $all; then
    mapfile -t files < <(tracked_files config/zsh config/zshenv)
  fi
  for f in ${files[@]+"${files[@]}"}; do
    step "$f" zsh -n "$f"
  done
}

check_main "$@"
