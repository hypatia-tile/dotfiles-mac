#!/usr/bin/env bash
# Every gate the hooks run, over the whole tree (ADR 0032 rollout step 4, #206).
# This is the part of the `preflight` skill that is pass or fail; the closure
# diff and the collision check need a reader and stay in the skill.
#
# It runs the hook stages through the tracked stubs, so each stage enters the
# devShell its hook enters and dispatches through lefthook.yml: the commands
# live in the check scripts and the stage mapping lives there, and neither is
# written a second time here. HOOK_FILES=all makes every check see everything
# (bin/lib/hook-files.sh), which also covers uncommitted and untracked files.
# --force, which the stubs pass on to `lefthook run`, is needed as well:
# Lefthook skips every command when nothing is staged or pushed, even one that
# takes no file template (measured on Lefthook 2.1.15, #206), so without it a
# clean tree would report every stage as passed having run nothing.
#
# The commit-msg stage has no message to read outside a commit, so its
# whole-tree counterpart is the branch's commits since origin/main, the range
# CI checks. CI also checks the pull request's title, which has no local form.
#
# Build only: nothing is switched or activated (ADR 0003).
#
# Usage: bin/preflight.sh
# Exit:  0 every stage passed; 1 a stage failed, or the hooks are not installed
set -uo pipefail

[[ $# -eq 0 ]] || {
  echo "usage: $(basename "$0")" >&2
  exit 2
}

cd "$(git rev-parse --show-toplevel)" || exit 2

results=()
failed=0

# stage NAME COMMAND...
stage() {
  local name=$1
  shift
  echo "==> $name"
  if "$@"; then
    results+=("ok   $name")
  else
    results+=("FAIL $name")
    failed=1
  fi
}

stage 'hooks installed' bin/hooks-health.sh
stage pre-commit env HOOK_FILES=all .githooks/pre-commit --force
stage 'commit messages' nix develop --no-update-lock-file --option warn-dirty false \
  .#default -c bin/check-commits.sh
stage pre-push env HOOK_FILES=all .githooks/pre-push --force </dev/null

echo
printf '%s\n' "${results[@]}"
exit "$failed"
