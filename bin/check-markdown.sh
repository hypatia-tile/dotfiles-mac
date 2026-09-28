#!/usr/bin/env bash
# Markdown lint with markdownlint-cli2, at the version the check devShell pins
# (ADR 0032). Rules live in .markdownlint.jsonc and the paths it skips in
# .markdownlint-cli2.jsonc, which applies them to files named on the command
# line as well as to globs. A change to either file lints everything.
#
# Usage: nix develop -c bin/check-markdown.sh [--applies] [FILE...]
#        (the contract is in bin/lib/check.sh)
set -euo pipefail
# shellcheck source=lib/check.sh source-path=SCRIPTDIR
. "$(dirname "$0")/lib/check.sh"

scope '*.md' .markdownlint.jsonc .markdownlint-cli2.jsonc

run_check() {
  local files=() f
  need markdownlint-cli2
  for f in "$@"; do
    case $f in
      .markdownlint*.jsonc) CHECK_ALL=true ;;
      *) files+=("$f") ;;
    esac
  done
  if $CHECK_ALL; then
    step markdownlint markdownlint-cli2 '**/*.md'
  elif [[ ${#files[@]} -gt 0 ]]; then
    step markdownlint markdownlint-cli2 "${files[@]}"
  fi
}

check_main "$@"
