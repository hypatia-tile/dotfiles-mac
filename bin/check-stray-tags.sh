#!/usr/bin/env bash
# Stray closing tags. An agent's file-writing tool occasionally appends one,
# such as `</content>`, to a file it creates (AGENTS.md), which then breaks Nix
# evaluation or lint. It lands at the end of the file, so only the last
# non-blank line is read: prose that names the tag is not a finding.
#
# Usage: bin/check-stray-tags.sh [--applies] [FILE...]
#        (the contract is in bin/lib/check.sh)
set -euo pipefail
# shellcheck source=lib/check.sh source-path=SCRIPTDIR
. "$(dirname "$0")/lib/check.sh"

scope '*'

# shellcheck disable=SC2329 # invoked through step
scan() {
  local f last found=0
  for f in "$@"; do
    [[ -f $f && ! -L $f ]] || continue
    last=$(tail -n 5 "$f" | awk 'NF { l = $0 } END { print l }')
    if [[ $last == *'</content>' ]]; then
      echo "$f: ends with a stray </content>"
      found=1
    fi
  done
  return "$found"
}

run_check() {
  local files=("$@")
  if $CHECK_ALL; then
    mapfile -t files < <(tracked_files '*')
  fi
  step stray-tags scan ${files[@]+"${files[@]}"}
}

check_main "$@"
