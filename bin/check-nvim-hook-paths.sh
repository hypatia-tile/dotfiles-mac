#!/usr/bin/env bash
# Every path the nvim projection hook names still exists (#87). The hook
# returns early when it cannot find what it names, which is correct for
# another repository and invisible when the path is simply stale — it shipped
# dead twice that way.
#
# Every `root .. "/..."` in the hook is a path it expects to find. The scope is
# the hook and those same paths, read from the hook, so the rename under
# modules/ that broke it last time is in scope, though it trips no nvim filter.
#
# Usage: bin/check-nvim-hook-paths.sh [--applies] [FILE...]
#        (the contract is in bin/lib/check.sh)
set -euo pipefail
# shellcheck source=lib/check.sh source-path=SCRIPTDIR
. "$(dirname "$0")/lib/check.sh"

hook=config/nvim/lua/autocmds.lua

named_paths() {
  [[ -f $hook ]] || return 0
  grep -oE 'root \.\. "/[^"]+"' "$hook" | sed -e 's/.*"\///' -e 's/"$//' | sort -u
}

scope "$hook"
while IFS= read -r p; do
  p=${p%/}
  scope "$p" "$p/*"
done < <(named_paths)
check_gate "$@"

if [[ ! -f $hook ]]; then
  echo "MISSING $hook — the hook itself is gone"
  exit 1
fi
rc=0
while IFS= read -r p; do
  if [[ -e $p ]]; then
    echo "ok      $p"
  else
    echo "MISSING $p — the hook names it and it is not there"
    rc=1
  fi
done < <(named_paths)
exit "$rc"
