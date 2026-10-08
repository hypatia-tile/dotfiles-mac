#!/usr/bin/env bash
# Locked inputs do not ride along with other changes (ADR 0011, ADR 0032
# rollout step 5, #208). flake.lock moves in dedicated commits, so that a
# lock update can be reviewed, verified and reverted on its own.
#
# The rule the history actually follows is narrower than "flake.lock is never
# committed with anything else": adding an input to flake.nix has to lock it,
# and `0a3d9c0` did exactly that. So a commit that changes flake.lock together
# with any other file fails only if a node present on both sides has a
# different `locked` entry. Adding or removing a node is allowed. A commit
# that changes flake.lock alone is the dedicated commit, and always passes.
#
# Outside the file contract of bin/lib/check.sh, like check-commits.sh: it
# reads commits, not changed files. It has no scope and no --applies.
#
# Usage: nix develop -c bin/check-lock.sh --staged
#          the commit about to be made (the pre-commit hook)
#        nix develop -c bin/check-lock.sh [BASE [HEAD]]
#          each commit in BASE..HEAD (default origin/main..HEAD), merges aside
# Exit:  0 no locked input rode along; 1 one did; 2 usage error, or no jq
set -uo pipefail

usage() {
  echo "usage: $(basename "$0") --staged | [BASE [HEAD]]" >&2
  exit 2
}

if ! command -v jq >/dev/null 2>&1; then
  echo "$(basename "$0"): 'jq' is not on PATH; run it as: nix develop -c $0" >&2
  exit 2
fi

cd "$(dirname "$0")/.." || exit 2

# moved OLD NEW: the nodes on both sides whose `locked` differs, one per line.
# OLD and NEW are object names as `git show` reads them.
moved() {
  jq -rn --slurpfile a <(git show "$1" 2>/dev/null || echo '{}') \
    --slurpfile b <(git show "$2" 2>/dev/null || echo '{}') '
    ($a[0].nodes // {}) as $old | ($b[0].nodes // {}) as $new
    | $old | keys[]
    | select($new[.] != null and $old[.].locked != $new[.].locked)'
}

# judge WHAT OLD NEW FILE...: report and fail if flake.lock rode along.
judge() {
  local what=$1 old=$2 new=$3 nodes
  shift 3
  [[ $# -gt 1 ]] || return 0
  printf '%s\n' "$@" | grep -qxF flake.lock || return 0
  if ! nodes=$(moved "$old" "$new"); then
    echo "$what: flake.lock could not be read as JSON" >&2
    return 1
  fi
  [[ -n $nodes ]] || return 0
  echo "$what: changes flake.lock together with other files, and moves locked inputs:" >&2
  echo "  ${nodes//$'\n'/$'\n  '}" >&2
  echo "  Commit the lock update on its own (ADR 0011)." >&2
  return 1
}

files=()
case ${1-} in
  --staged)
    [[ $# -eq 1 ]] || usage
    while IFS= read -r -d '' f; do files+=("$f"); done \
      < <(git diff --cached --name-only --no-renames -z)
    judge 'the staged commit' HEAD:flake.lock :flake.lock ${files[@]+"${files[@]}"} || exit 1
    ;;
  -*) usage ;;
  *)
    [[ $# -le 2 ]] || usage
    base=${1:-origin/main} head=${2:-HEAD}
    revs=$(git rev-list --no-merges --reverse "$base..$head") || exit 2
    failed=0
    for c in $revs; do
      git rev-parse --verify --quiet "$c^" >/dev/null || continue
      files=()
      while IFS= read -r -d '' f; do files+=("$f"); done \
        < <(git diff-tree --no-commit-id --name-only --no-renames -r -z "$c^" "$c")
      judge "$(git log -1 --format='%h %s' "$c")" "$c^:flake.lock" "$c:flake.lock" \
        ${files[@]+"${files[@]}"} || failed=1
    done
    exit "$failed"
    ;;
esac
