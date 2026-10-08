#!/usr/bin/env bash
# Are this clone's Git hooks installed, so that commits and pushes run the
# gates (ADR 0032)? Hooks are only as strong as their installation: a fresh
# clone runs none until the owner sets core.hooksPath (the manual-setup skill),
# and nothing else notices when that is missing.
#
# Healthy means:
#   - core.hooksPath, as Git resolves it from every config scope, is .githooks;
#   - lefthook.yml exists, since the stubs refuse to run without it;
#   - every stage lefthook.yml declares has a stub in .githooks/ that Git will
#     execute, and every stub there has a stage, so neither side runs alone.
#
# It reads and never changes anything: the fix is the owner's (manual-setup).
# Unlike the bin/check-*.sh scripts it checks the clone's state, not files, so
# it is not part of CI. bin/preflight.sh runs it first.
#
# Usage: bin/hooks-health.sh [REPO]
#          REPO defaults to the repository this script is in
# Exit:  0 healthy; 1 not; 2 REPO is not a Git working tree
set -uo pipefail

[[ $# -le 1 ]] || {
  echo "usage: $(basename "$0") [REPO]" >&2
  exit 2
}

repo=${1:-$(dirname "$0")/..}
if ! root=$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null); then
  echo "$(basename "$0"): '$repo' is not a Git working tree" >&2
  exit 2
fi
cd "$root" || exit 2

failed=0
ok() { echo "ok   $1"; }
fail() {
  echo "FAIL $1"
  failed=1
}

path=$(git config core.hooksPath)
if [[ $path == .githooks ]]; then
  ok 'core.hooksPath is .githooks'
elif [[ -z $path ]]; then
  fail 'core.hooksPath is unset: commits and pushes run none of the gates'
else
  fail "core.hooksPath is '$path', not .githooks: other hooks than the gates run"
fi

if [[ ! -f lefthook.yml ]]; then
  fail 'lefthook.yml is missing: every stub refuses to run'
else
  ok 'lefthook.yml exists'
  # A stage is a top-level key with nothing after the colon; a setting such
  # as `no_auto_install: true` has its value on the same line.
  stages=$(sed -n 's/^\([a-z][a-z-]*\):[[:space:]]*$/\1/p' lefthook.yml)
  for stage in $stages; do
    if [[ ! -e .githooks/$stage ]]; then
      fail "$stage: declared in lefthook.yml, no stub in .githooks/"
    elif [[ ! -x .githooks/$stage ]]; then
      fail "$stage: .githooks/$stage is not executable, so Git skips it silently"
    else
      ok "$stage: stub present and executable"
    fi
  done
  for stub in .githooks/*; do
    [[ -e $stub ]] || continue
    grep -qxF "${stub#.githooks/}" <<<"$stages" ||
      fail "${stub#.githooks/}: a stub with no stage in lefthook.yml"
  done
fi

exit "$failed"
