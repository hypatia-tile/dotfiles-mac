#!/usr/bin/env bash
# Verify an nvim-config pin bump before shipping it (ADR 0014, nvim-bump skill).
#
# The Neovim config is the pinned non-flake input `nvim-config`, placed
# read-only into home via modules/home/files.nix. Bumping the pin changes what
# ~/.config/nvim resolves to, so before opening the PR this proves:
#   1. the system closure still builds against the frozen lock (no switch), and
#   2. the built .config/nvim resolves to the new pinned nvim-config revision,
# and optionally asserts that a path is present/absent in the new tree (e.g. a
# file the bump removed). It never switches and never touches the lock
# (--no-update-lock-file), per the repo hard rules.
#
# With --emit-pr-body it prints a ready-to-paste PR body (filled from
# .claude/skills/nvim-bump/pr-body.md) to stdout instead of the report, so the
# ship-pr flow can `gh pr create --body-file`.
#
# Usage:
#   bin/nvim-bump-check.sh [--assert-absent PATH]... [--assert-present PATH]...
#                          [--host HOST] [--base REF] [--emit-pr-body]
#
#   PATH is relative to the nvim config root (e.g. lua/snippets/lean.lua).
#   --host   darwinConfigurations attribute to build (default: the sole host).
#   --base   git ref whose flake.lock is the "old" pin (default: origin/main
#            or main). The bump may be committed on the branch or still in the
#            working tree; either way "new" is the working-tree flake.lock.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

clone="${NVIM_CONFIG_CLONE:-$HOME/ghqrepo/github.com/hypatia-tile/nvim-config}"
host=""
base=""
emit_pr_body=false
assert_absent=()
assert_present=()

while [ $# -gt 0 ]; do
  case "$1" in
    --assert-absent)  assert_absent+=("$2"); shift 2 ;;
    --assert-present) assert_present+=("$2"); shift 2 ;;
    --host)           host="$2"; shift 2 ;;
    --base)           base="$2"; shift 2 ;;
    --emit-pr-body)   emit_pr_body=true; shift ;;
    -h|--help)        sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; exit 2 ;;
  esac
done

# Anything that is not the PR body (progress, warnings) goes to stderr so that
# --emit-pr-body yields a clean body on stdout.
log() { echo "$@" >&2; }
die() { echo "error: $*" >&2; exit 1; }

command -v jq >/dev/null || die "jq is required"

# --- Resolve host, user, and the old/new pinned revisions ------------------
if [ -z "$host" ]; then
  host="$(grep -h 'hostname *=' hosts/*.nix | head -1 | sed 's/.*"\(.*\)".*/\1/')"
  [ -n "$host" ] || die "could not infer host from hosts/*.nix; pass --host"
fi
user="$(nix eval --raw --file modules/common.nix username)"

if [ -z "$base" ]; then
  for ref in origin/main main; do
    if git rev-parse --verify --quiet "$ref" >/dev/null; then base="$ref"; break; fi
  done
fi

lock_rev() { jq -r '.nodes["nvim-config"].locked.rev'; }
new_rev="$(lock_rev < flake.lock)"
[ -n "$new_rev" ] && [ "$new_rev" != "null" ] || die "no nvim-config rev in flake.lock"
if [ -n "$base" ]; then
  old_rev="$(git show "$base:flake.lock" 2>/dev/null | lock_rev || true)"
else
  old_rev=""
fi
[ -n "$old_rev" ] || old_rev="(unknown)"

short() { printf '%.7s' "$1"; }
if [ "$old_rev" = "$new_rev" ]; then
  log "warning: flake.lock nvim-config pin equals $base ($(short "$new_rev")); nothing bumped"
fi

# --- Build the closure against the frozen lock (never switch) ---------------
log "==> building closure for .#$host (frozen lock, no switch)"
if ! darwin-rebuild build --flake ".#$host" --no-update-lock-file >&2; then
  die "closure build failed"
fi

# --- Resolve the built .config/nvim source path -----------------------------
nvim_path="$(nix eval --raw --no-update-lock-file \
  ".#darwinConfigurations.$host.config.home-manager.users.$user.xdg.configFile.\"nvim\".source")"
[ -d "$nvim_path" ] || die "resolved nvim source is not a directory: $nvim_path"
log "==> .config/nvim resolves to $nvim_path"

# --- Path assertions on the new tree ----------------------------------------
verified_lines=""
for p in "${assert_absent[@]}"; do
  if [ -e "$nvim_path/$p" ]; then
    die "assertion failed: '$p' should be ABSENT but exists in the new tree"
  fi
  log "    ok: '$p' is absent in the new tree"
  verified_lines+="- \`$p\` absent in the new tree (verified)."$'\n'
done
for p in "${assert_present[@]}"; do
  if [ ! -e "$nvim_path/$p" ]; then
    die "assertion failed: '$p' should be PRESENT but is missing in the new tree"
  fi
  log "    ok: '$p' is present in the new tree"
  verified_lines+="- \`$p\` present in the new tree (verified)."$'\n'
done

# --- Derive the PR range and change bullets from the nvim-config clone -------
pr_range=""
change_bullets=""
if [ "$old_rev" != "(unknown)" ] && [ -d "$clone/.git" ]; then
  subjects="$(git -C "$clone" log --oneline --no-merges "$old_rev..$new_rev" 2>/dev/null || true)"
  if [ -n "$subjects" ]; then
    nums="$(printf '%s\n' "$subjects" | grep -oE '#[0-9]+' | tr -d '#' | sort -n | uniq)"
    if [ -n "$nums" ]; then
      lo="$(printf '%s\n' "$nums" | head -1)"
      hi="$(printf '%s\n' "$nums" | tail -1)"
      if [ "$lo" = "$hi" ]; then pr_range="#${lo}"; else pr_range="#${lo}–#${hi}"; fi
    fi
    # One bullet per landed PR: "- **#NN** <subject without the (#NN) tag>".
    change_bullets="$(printf '%s\n' "$subjects" | sed -E \
      -e 's/^[0-9a-f]+ //' \
      -e 's/^(.*) \(#([0-9]+)\)$/- **#\2** \1/' \
      -e 't' -e 's/^/- /')"
  fi
fi
[ -n "$pr_range" ] || pr_range="the range $(short "$old_rev")..$(short "$new_rev")"
[ -n "$change_bullets" ] || change_bullets="- see nvim-config history $(short "$old_rev")..$(short "$new_rev")"

# --- Emit either the PR body or a human report ------------------------------
if $emit_pr_body; then
  template="$repo_root/.claude/skills/nvim-bump/pr-body.md"
  [ -f "$template" ] || die "PR body template not found: $template"
  # Strip the leading doc comment, drop the {{VERIFIED}} line when there were
  # no assertions (so the bullet list stays contiguous), then fill placeholders.
  OLD_REV="$(short "$old_rev")" NEW_REV="$(short "$new_rev")" \
  PR_RANGE="$pr_range" CHANGE_BULLETS="$change_bullets" \
  HOST="$host" NVIM_STORE_PATH="$nvim_path" \
  VERIFIED="${verified_lines%$'\n'}" \
    perl -0pe '
      s/\A<!--.*?-->\s*//s;
      s/\{\{VERIFIED\}\}\n/$ENV{VERIFIED} eq "" ? "" : "$ENV{VERIFIED}\n"/ge;
      s/\{\{(\w+)\}\}/exists $ENV{$1} ? $ENV{$1} : "{{$1}}"/ge;
    ' "$template"
else
  log ""
  log "nvim-bump-check: PASS"
  log "  host:       $host"
  log "  pin:        $(short "$old_rev") -> $(short "$new_rev")"
  log "  PR range:   $pr_range"
  log "  nvim path:  $nvim_path"
  [ -n "$verified_lines" ] && log "  assertions: all passed"
fi
