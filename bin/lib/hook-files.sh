#!/usr/bin/env bash
# Hand a check script the files a Git hook is about, deletions included
# (ADR 0032 rollout step 3, #196).
#
# Lefthook's own file lists cannot do this. {staged_files} and {push_files}
# keep only paths that exist, and so does a job's custom `files:` command,
# because all of them go through the same existing-files filter (measured on
# the Lefthook the devShell pins, 2.1.14). bin/lib/check.sh holds the opposite
# rule: a deleted FILE still counts, because deleting a file can break what
# remains. With Lefthook's lists, a commit that deletes a SKILL.md and edits a
# README hands check-skills.sh only the README, and the check is skipped.
#
# So lefthook.yml calls the checks through this, declares no glob, and passes
# no file template. Which files concern a check is still decided by the check.
#
# Usage: bin/lib/hook-files.sh staged CHECK [ARG...]
#          the staged changes, for pre-commit
#        bin/lib/hook-files.sh pushed CHECK [ARG...]
#          the branch's changes since it left origin/main, for pre-push —
#          the same diff CI's changes job takes
#
# CHECK runs with ARG... and then the files. Renames count as a deletion and an
# addition (--no-renames), so the old path is passed as well. Nothing staged
# means nothing to check, and exits 0. For `pushed`, a missing origin/main
# makes the range unknowable, and CHECK runs with no files, which checks
# everything: the contract runs more, never less, when the list is lost.
set -euo pipefail

usage() {
  echo "usage: $(basename "$0") staged|pushed CHECK [ARG...]" >&2
  exit 2
}

[[ $# -ge 2 ]] || usage
mode=$1
shift

cd "$(git rev-parse --show-toplevel)"

files=()
case $mode in
  staged)
    while IFS= read -r -d '' f; do files+=("$f"); done \
      < <(git diff --cached --name-only --no-renames -z)
    [[ ${#files[@]} -gt 0 ]] || exit 0
    ;;
  pushed)
    if git rev-parse --verify --quiet origin/main >/dev/null; then
      while IFS= read -r -d '' f; do files+=("$f"); done \
        < <(git diff --name-only --no-renames -z origin/main...HEAD)
      [[ ${#files[@]} -gt 0 ]] || exit 0
    fi
    ;;
  *) usage ;;
esac

exec "$@" ${files[@]+"${files[@]}"}
