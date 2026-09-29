#!/usr/bin/env bash
# The nvim payload typechecks under LuaLS at Warning level, with the LuaLS and
# the Neovim the check devShell's nvim shell pins (ADR 0032).
#
# LuaLS reads no environment variables in its config, so the library paths
# lazydev supplies in the editor are resolved here: $VIMRUNTIME, and the lua
# directory of every plugin restored to lazy-lock.json. They are merged into
# config/nvim/.github/luarc.ci.json and passed with --configpath, which leaves
# the tracked config/nvim/.luarc.json, the editor's, untouched.
#
# The plugins' types are part of what is checked, so a change to the lock runs
# it as well as a change to the Lua.
#
# Usage: nix develop .#nvim -c bin/check-luals.sh [--applies] [FILE...]
#        (the contract is in bin/lib/check.sh; FILE only decides whether the
#        whole check runs)
set -euo pipefail
# shellcheck source=lib/check.sh source-path=SCRIPTDIR
. "$(dirname "$0")/lib/check.sh"

NVIM_DIR=config/nvim

scope "$NVIM_DIR/*.lua" "$NVIM_DIR/lazy-lock.json" "$NVIM_DIR/.luarc.json" \
  "$NVIM_DIR/.github/luarc.ci.json"
check_gate "$@"

need nvim deno lua-language-server jq

"$NVIM_DIR/bin/check" --restore || exit 1

vimruntime=$(nvim --headless --clean -c 'lua io.write(vim.env.VIMRUNTIME)' -c qa 2>/dev/null)
data=$(NVIM_APPNAME=nvim-dev nvim --headless --clean -c 'lua io.write(vim.fn.stdpath("data"))' -c qa 2>/dev/null)
[[ -d $vimruntime && -d $data/lazy ]] || {
  echo "$(basename "$0"): could not resolve \$VIMRUNTIME ($vimruntime) or the plugin dir ($data/lazy)" >&2
  exit 2
}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
printf '%s\n' "$vimruntime" "$data"/lazy/*/lua | jq -R . | jq -s . > "$work/libs.json"
jq --slurpfile libs "$work/libs.json" '. + {"workspace.library": $libs[0]}' \
  "$NVIM_DIR/.github/luarc.ci.json" > "$work/luarc.json"
echo "library: $(jq length "$work/libs.json") paths (\$VIMRUNTIME and each plugin's lua dir)"

cd "$NVIM_DIR"
lua-language-server --check . --checklevel Warning \
  --configpath "$work/luarc.json" --logpath "$work/log" || exit 1
