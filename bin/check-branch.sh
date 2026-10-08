#!/usr/bin/env bash
# Commits are not made on `main` (ADR 0032 rollout step 5, #208). Work happens
# on feature branches off `main`, and the ruleset refuses direct pushes to it
# (ADR 0012), so a commit made on `main` locally is otherwise discovered only
# when the push is refused.
#
# Outside the file contract of bin/lib/check.sh, like check-secrets.sh: it
# reads branches, not changed files. It has no scope and no --applies, and CI
# never runs it — CI runs on pull-request merges and on `main` itself, where
# being on `main` is the point.
#
# Usage: bin/check-branch.sh --commit
#          the commit about to be made is not on `main` (the pre-commit hook)
#        bin/check-branch.sh
#          local `main` holds no commit that origin/main does not (preflight's
#          whole-tree run): being on `main` is fine, having committed there is not
# Exit:  0 clean; 1 a commit on `main`; 2 usage error, or no origin/main to
#        compare with
set -uo pipefail

usage() {
  echo "usage: $(basename "$0") [--commit]" >&2
  exit 2
}

cd "$(dirname "$0")/.." || exit 2

case $# in
  0) ;;
  1)
    [[ $1 == --commit ]] || usage
    # A detached HEAD (a rebase in progress, a bisect) is on no branch.
    if [[ $(git symbolic-ref --quiet --short HEAD) == main ]]; then
      echo "$(basename "$0"): refusing a commit on main; branch off it first:" >&2
      echo "  git switch -c <type>/<topic>" >&2
      exit 1
    fi
    exit 0
    ;;
  *) usage ;;
esac

git rev-parse --verify --quiet refs/heads/main >/dev/null || exit 0
if ! git rev-parse --verify --quiet refs/remotes/origin/main >/dev/null; then
  echo "$(basename "$0"): no origin/main to compare local main with" >&2
  exit 2
fi
ahead=$(git rev-list refs/remotes/origin/main..refs/heads/main)
if [[ -n $ahead ]]; then
  echo "$(basename "$0"): local main holds commits that origin/main does not:" >&2
  git log --oneline --no-decorate refs/remotes/origin/main..refs/heads/main >&2
  echo "Move them to a branch; resetting main is the owner's call." >&2
  exit 1
fi
exit 0
