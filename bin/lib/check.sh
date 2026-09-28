# shellcheck shell=bash
# The contract every bin/check-*.sh follows (ADR 0032), implemented once.
#
#   check-<name>.sh FILE...            check the FILEs in scope; none in scope: exit 0
#   check-<name>.sh                    check everything
#   check-<name>.sh --applies FILE...  run nothing; exit 0 if any FILE is in
#                                      scope, 1 if none is
#
# No FILE means everything, so a caller that loses its file list runs more,
# never less. FILEs are repository-relative, as git and lefthook print them. A
# FILE that no longer exists still counts as in scope: deleting a file can
# break what remains.
#
# Exit: 0 clean; 1 a finding (or, for --applies, not in scope); 2 the check
# could not run.
#
# A script sources this, declares `scope PATTERN...` (and optionally
# `exclude PATTERN...`, which wins), defines `run_check`, and ends with
# `check_main "$@"`. Patterns are `case` patterns matched against the whole
# path, so `*` crosses `/`. run_check receives the in-scope FILEs that
# still exist; CHECK_ALL says whether it was asked for everything instead, and
# a whole-tree check ignores both. Each tool runs through `step`, which records
# a failure and carries on, so one run reports every finding.

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 2

CHECK_SCOPE=()
CHECK_EXCLUDE=()
# shellcheck disable=SC2034 # read by the sourcing script's run_check
CHECK_ALL=false
CHECK_FAILED=0

scope() { CHECK_SCOPE+=("$@"); }
exclude() { CHECK_EXCLUDE+=("$@"); }

in_scope() {
  local pat
  for pat in ${CHECK_EXCLUDE[@]+"${CHECK_EXCLUDE[@]}"}; do
    # shellcheck disable=SC2254 # the pattern is meant to match as a glob
    case $1 in $pat) return 1 ;; esac
  done
  for pat in "${CHECK_SCOPE[@]}"; do
    # shellcheck disable=SC2254 # the pattern is meant to match as a glob
    case $1 in $pat) return 0 ;; esac
  done
  return 1
}

# need TOOL...: the tools come from the check devShell, not from the machine.
need() {
  local tool
  for tool in "$@"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      echo "$(basename "$0"): '$tool' is not on PATH; run it as: nix develop -c $0" >&2
      exit 2
    fi
  done
}

# step NAME COMMAND...
step() {
  local name=$1
  shift
  if "$@"; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    CHECK_FAILED=1
  fi
}

# tracked_files PATTERN...: tracked and untracked-but-not-ignored files that
# exist and are in scope, which is what "everything" means for a file-level
# check. PATTERNs are git pathspecs; '*' is every file.
tracked_files() {
  local f
  git ls-files --cached --others --exclude-standard -- "$@" | sort -u | while IFS= read -r f; do
    [[ -e $f ]] && in_scope "$f" && printf '%s\n' "$f"
  done
}

check_main() {
  local applies=false matched=false f
  local files=()

  if [[ ${1-} == --applies ]]; then
    applies=true
    shift
    if [[ $# -eq 0 ]]; then
      echo "$(basename "$0"): --applies needs at least one FILE" >&2
      exit 2
    fi
  elif [[ ${1-} == -* ]]; then
    echo "usage: $(basename "$0") [--applies] [FILE...]" >&2
    exit 2
  fi

  if [[ $# -eq 0 ]]; then
    # shellcheck disable=SC2034 # read by the sourcing script's run_check
    CHECK_ALL=true
  else
    for f in "$@"; do
      f=${f#./}
      in_scope "$f" || continue
      matched=true
      [[ -e $f ]] && files+=("$f")
    done
    if $applies; then
      $matched && exit 0
      exit 1
    fi
    $matched || exit 0
  fi

  run_check "${files[@]}"
  exit "$CHECK_FAILED"
}
