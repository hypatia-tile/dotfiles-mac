#!/usr/bin/env bash
# Commit messages are Conventional Commits, as commitlint.config.mjs defines,
# with the commitlint the check devShell pins (ADR 0032).
#
# The one check outside the file contract of bin/lib/check.sh: it reads commit
# messages, not changed files. It has no scope and no --applies, and CI's
# changes job never asks it — every commit concerns it.
#
# Usage: nix develop -c bin/check-commits.sh [BASE [HEAD]]
#          the commits in BASE..HEAD (default origin/main..HEAD)
#        nix develop -c bin/check-commits.sh --message FILE
#          one message: a file (the commit-msg hook), or - for stdin
# Exit:  0 conventional; 1 a message is not; 2 usage error, or no commitlint
set -euo pipefail

usage() {
  echo "usage: $(basename "$0") [BASE [HEAD]] | --message FILE|-" >&2
  exit 2
}

if ! command -v commitlint >/dev/null 2>&1; then
  echo "$(basename "$0"): 'commitlint' is not on PATH; run it as: nix develop -c $0" >&2
  exit 2
fi

case ${1-} in
  --message)
    [[ $# -eq 2 ]] || usage
    message=$2
    # Resolved before the cd below, which would otherwise change what a
    # relative path means.
    [[ $message == - ]] || message="$(cd "$(dirname "$message")" && pwd)/$(basename "$message")"
    cd "$(dirname "$0")/.."
    if [[ $message == - ]]; then
      commitlint || exit 1
    else
      commitlint --edit "$message" || exit 1
    fi
    ;;
  -*)
    usage
    ;;
  *)
    [[ $# -le 2 ]] || usage
    cd "$(dirname "$0")/.."
    commitlint --from "${1:-origin/main}" --to "${2:-HEAD}" || exit 1
    ;;
esac
