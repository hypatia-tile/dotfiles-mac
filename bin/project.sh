#!/usr/bin/env bash
# Project this repository's payloads into $HOME (ADR 0026).
#
# `~/.config` is a projection of this repository, not an editing surface: each
# declared payload is copied in and made read-only, so a change can only be
# made here. What the declaration says lives in modules/payloads.tsv.
#
# Two dispositions:
#   copy  a read-only copy — the default, and what provides the prevention
#         ADR 0021 gave up when it moved to symlinks
#   link  a symlink to the working tree, for a file the tool must write back
#         into the repository (lazy-lock.json). A writable copy cannot serve:
#         it diverges instead of updating.
#
# What this deliberately does NOT do is force-overwrite. `dot-link.sh` was
# retired for `rm -rf` + `ln -s` (ADR 0001), and a target that exists without
# being in the manifest is backed up rather than replaced. The manifest is also
# what makes removal safe: only paths this script placed are ever deleted, so
# runtime state living *beside* a payload — herdr's logs next to the
# config.toml this repository owns — is untouched by construction.
#
# Inside a declared directory it is not, and the sentence above used to claim
# otherwise. Replacing a directory payload takes the whole target, so whatever
# the tool wrote there goes with it (#94). The rule that prevents this lives
# with the declaration in modules/payloads.tsv, because it is a property of
# what is declared rather than of this script. What this script owes it is to
# stop being silent: every entry a replacement would remove is reported.
#
# Usage:
#   bin/project.sh            place payloads, prune what left the declaration
#   bin/project.sh --check    report drift and exit non-zero; changes nothing
#   bin/project.sh --validate check the declaration alone; touches no $HOME path
#
# Exit: 0 in sync (or applied, or sound); 1 drift found in --check; 2 a
# declaration this script cannot act on, or any other error. The two are worth
# keeping apart: on a migration drift is the *expected* state, so only 2 means
# something is wrong.
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
decl="$repo_root/modules/payloads.tsv"
manifest="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-mac/projected"

check_only=false
validate_only=false
case "${1:-}" in
  --check) check_only=true ;;
  --validate) validate_only=true ;;
  # Rejected rather than ignored: a mistyped --chek used to fall through to a
  # full placement, which is the one outcome someone reaching for a read-only
  # mode does not want.
  "") ;;
  *) echo "project: unknown option '$1' (expected --check or --validate)" >&2; exit 2 ;;
esac

# Paths this script needs in order to run at all, and therefore cannot place.
# ~/.config/nix is the one that proved this (#85): the declaration used to be a
# Nix file, `nix eval` needs the experimental features the user nix.conf
# enables, and projecting that payload left the machine with nothing placed —
# the failure arriving *after* Home Manager had released the path.
#
# The declaration is now read without a parser, so nix is no longer among this
# script's needs and that particular cycle cannot recur. The entry stays: the
# repository still declares config/nix in files.nix, and the guard is what
# stops someone moving it back without knowing why it is there. Refusing here
# rather than in a comment, because a comment cannot fail a build.
SELF_DEPENDENCIES=".config/nix"

[ -f "$decl" ] || { echo "project: no declaration at $decl" >&2; exit 2; }

# `target<TAB>source<TAB>mode`, one payload per line; `#` comments and blank
# lines dropped. No parser on purpose — see SELF_DEPENDENCIES above.
declared=$(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$decl" | sort)

# --- validate the declaration -----------------------------------------------
# Everything that can stop this script before it touches $HOME. All of it is a
# property of the repository alone — no target, no manifest — which is what
# makes it runnable in CI and in preflight rather than only at switch time.
#
# That earliness is the point (#91). The activation hook runs *after*
# linkGeneration, so a projector that cannot run fails in the window where Home
# Manager has released the payload and this script has not yet placed it,
# leaving it neither linked nor placed. Every condition below is one that would
# land there; found here, it is found while the old placement is still intact.
#
# Reports every problem rather than the first: a declaration is usually edited
# in one sitting, and a gate that reveals one error per run wastes the trip.
validate_declaration() {
  local rc=0 t sc m self
  while IFS=$'\t' read -r t sc m; do
    [ -n "$t" ] || continue

    if [ -z "$sc" ] || [ -z "$m" ]; then
      echo "project: malformed line in $decl (expected three tab-separated fields):" >&2
      echo "  $t" >&2
      rc=1
      continue
    fi

    case "$m" in
      copy | link) ;;
      *)
        echo "project: unknown mode '$m' for $t (expected copy or link)" >&2
        rc=1
        ;;
    esac

    [ -e "$repo_root/$sc" ] || {
      echo "project: missing source $repo_root/$sc, declared for $t" >&2
      rc=1
    }

    for self in $SELF_DEPENDENCIES; do
      [ "$t" = "$self" ] || continue
      echo "project: refusing to project $t — this script depends on it" >&2
      echo "  Placing it would make this script unable to run, at the point where" >&2
      echo "  Home Manager has already released the path. Keep it in files.nix." >&2
      rc=1
    done
  done <<< "$declared"

  # A target inside another target cannot work, in either order (#96). Placing
  # the outer one makes its directory read-only, so nothing can be placed
  # inside afterwards; placing the inner one first only means the outer one's
  # `rm -rf` deletes it. Two owners of one subtree is the thing ADR 0001 exists
  # to forbid, and there is no ordering that rescues it.
  #
  # Refused here rather than left to fail during placement, because there it
  # fails *after* Home Manager has released the path, writes no manifest — the
  # manifest write comes after both loops — and therefore does not converge:
  # the next run judges the half-placed target foreign and backs it up, and the
  # run after that backs up the backup.
  local targets outer
  targets=$(printf '%s\n' "$declared" | cut -f1)
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    while IFS= read -r outer; do
      [ -n "$outer" ] || continue
      case "$t" in
        "$outer"/*)
          echo "project: refusing $t — it is inside $outer, which is also declared" >&2
          echo "  A copy makes its directory read-only, so nothing can be placed" >&2
          echo "  inside it afterwards, and replacing it would delete what was." >&2
          echo "  Declare $outer's entries one by one instead, so that each" >&2
          echo "  target has exactly one owner." >&2
          rc=1
          ;;
      esac
    done <<< "$targets"
  done <<< "$targets"

  return "$rc"
}

validate_declaration || exit 2

if $validate_only; then
  echo "project --validate: declaration is sound"
  exit 0
fi

# Manifest lines are `<target>` or `<target><TAB>pending`. A bare line is a
# path currently placed; `pending` means it left the declaration on an earlier
# run and was reported rather than deleted (see the two-phase prune below).
# Manifests written before that distinction existed are all bare lines, which
# read correctly as "placed" — no migration needed.
placed=""
[ -f "$manifest" ] && placed=$(sort "$manifest")
# Membership tests must compare the target field alone: a `pending` line is
# still a path this script placed, and comparing whole lines would call it
# foreign and back it up.
placed_targets=$(printf '%s\n' "$placed" | cut -f1)

drift=0
note() { if $check_only; then echo "DRIFT: $*"; else echo "$*"; fi; }

# Say what a replacement would delete (#94). Placing over a directory is
# `rm -rf` plus a fresh copy, so every entry the target has and the source does
# not is about to go, and until now the run named none of them: the output was
# the same whether it removed nothing or a year of shell history.
#
# Reports rather than refuses, deliberately. A file deleted from the repository
# and a file the tool wrote are indistinguishable by looking at the filesystem,
# so refusing would block every intentional deletion. Under --check this lands
# before a switch, which is where it is worth reading.
#
# Called only for a target this script placed. One it did not place is moved
# aside whole by the backup above, so nothing is removed and saying otherwise
# would be a lie in the one direction that matters.
report_removals() {
  local src=$1 dst=$2 gone
  # Only a real directory can be hiding anything: a file target is replaced
  # whole, and a symlink target holds nothing of its own.
  { [ -d "$dst" ] && [ ! -L "$dst" ]; } || return 0

  if [ -d "$src" ]; then
    # `Only in <dir>: <name>` names what one side has and the other does not.
    # Keeping the target's side gives exactly what `rm -rf` would take, and
    # names the top-most entry rather than every file beneath it.
    while IFS= read -r gone; do
      case "$gone" in "$dst"/*) note "  removes $gone" ;; esac
    done <<< "$(diff -rq "$src" "$dst" 2>/dev/null |
      sed -n 's|^Only in \(.*\): \(.*\)$|\1/\2|p' || true)"
  else
    # A directory about to become a single file or a symlink: all of it goes.
    while IFS= read -r gone; do
      [ -n "$gone" ] || continue
      note "  removes $dst/$gone"
    done <<< "$(ls -A "$dst" 2>/dev/null || true)"
  fi
}

# Pick a backup name that does not exist yet (#96). `mv a b` where b is an
# existing *directory* moves a into it rather than failing, so a colliding
# backup nests silently — and the timestamp has one-second resolution, which
# two runs in the same second, or one failure retried immediately, collide on.
# Suffixing until the name is free removes the collision rather than making it
# less likely; the nesting is `mv`'s documented behaviour, not chance.
backup_path() {
  local base candidate n
  base="$1.bak-$(date +%Y%m%d%H%M%S)"
  candidate=$base
  n=0
  while [ -e "$candidate" ] || [ -L "$candidate" ]; do
    n=$((n + 1))
    candidate="$base.$n"
  done
  printf '%s' "$candidate"
}

# --- remove what left the declaration ---------------------------------------
# Only paths this script recorded. Anything else in those directories was put
# there by something else and is none of our business.
carried=""
while IFS=$'\t' read -r target state; do
  [ -n "$target" ] || continue
  if printf '%s\n' "$declared" | cut -f1 | grep -qxF "$target"; then
    continue
  fi

  # A payload leaves the declaration two ways: retired, or handed back to
  # another owner. Home Manager places a store symlink at the target when it
  # takes one back, and deleting that would undo a placement this script does
  # not own, so release the entry untouched.
  if readlink "$HOME/$target" 2>/dev/null | grep -q '^/nix/store/'; then
    note "release $target (owned by Home Manager again)"
    continue
  fi

  # Two-phase prune (#85). Before the new owner has placed anything, a hand-back
  # is indistinguishable from a retirement, and deleting on that first run is
  # what nearly destroyed ~/.config/nix: the entry was gone from the
  # declaration, Home Manager had not switched yet, and the editor hook would
  # have run this without anyone asking. So the first run reports and keeps the
  # entry; only a second run deletes. The delay costs one cycle on a deliberate
  # retirement, and buys the window back on every hand-back.
  if [ "$state" != "pending" ]; then
    drift=1
    note "pending $target (left the declaration; will be removed on the next run)"
    $check_only || carried+="$target"$'\t'"pending"$'\n'
    continue
  fi

  drift=1
  note "prune $target (left the declaration on an earlier run)"
  if ! $check_only; then
    chmod -R u+w "$HOME/$target" 2>/dev/null || true
    rm -rf "${HOME:?}/$target"
  fi
done <<< "$(printf '%s\n' "$placed")"

# --- place what the declaration asks for ------------------------------------
new_manifest=""
while IFS=$'\t' read -r target source mode; do
  [ -n "$target" ] || continue
  src="$repo_root/$source"
  dst="$HOME/$target"
  new_manifest+="$target"$'\n'

  # Whether this script placed the target decides both what happens to what is
  # already there and whether report_removals has anything to say: a target we
  # placed is replaced, and a target we did not is moved aside intact.
  placed_before=false
  printf '%s\n' "$placed_targets" | grep -qxF "$target" && placed_before=true

  # A target we did not place is never overwritten. Back it up and say so.
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if ! $placed_before; then
      drift=1
      note "backup $dst (exists but was not placed by this script)"
      if ! $check_only; then
        bak=$(backup_path "$dst")
        note "  moved to $bak"
        mv "$dst" "$bak"
      fi
    fi
  fi

  case "$mode" in
    link)
      if [ "$(readlink "$dst" 2>/dev/null || true)" != "$src" ]; then
        drift=1
        note "link $target -> $source"
        $placed_before && report_removals "$src" "$dst"
        if ! $check_only; then
          mkdir -p "$(dirname "$dst")"
          chmod -R u+w "$dst" 2>/dev/null || true
          rm -rf "$dst"
          ln -s "$src" "$dst"
        fi
      fi
      ;;
    copy)
      # diff -r compares content and structure; -q keeps it quiet. A symlink
      # left over from the ADR 0021 placement never compares equal to a
      # directory, so the migration case reports drift as it should.
      if [ -L "$dst" ] || ! diff -rq "$src" "$dst" >/dev/null 2>&1; then
        drift=1
        note "copy $target <- $source (read-only)"
        $placed_before && report_removals "$src" "$dst"
        if ! $check_only; then
          mkdir -p "$(dirname "$dst")"
          staging="$dst.projecting.$$"
          chmod -R u+w "$staging" 2>/dev/null || true
          rm -rf "$staging"
          cp -R "$src" "$staging"
          # Drop VCS bookkeeping that has no business in a deployed config.
          find "$staging" -name '.git' -maxdepth 2 -exec rm -rf {} + 2>/dev/null || true
          chmod -R a-w "$staging"
          # Swap last: the old copy stays in place until the new one is ready.
          chmod -R u+w "$dst" 2>/dev/null || true
          rm -rf "$dst"
          mv "$staging" "$dst"
        fi
      fi
      ;;
    *)
      # Unreachable: validate_declaration rejects any other mode above.
      echo "project: unknown mode '$mode' for $target" >&2
      exit 2
      ;;
  esac
done <<< "$declared"

if $check_only; then
  if [ "$drift" -eq 0 ]; then
    echo "project --check: in sync"
  else
    echo "project --check: drift found — run bin/project.sh" >&2
  fi
  exit "$drift"
fi

mkdir -p "$(dirname "$manifest")"
printf '%s%s' "$new_manifest" "$carried" | sed '/^$/d' | sort > "$manifest"
[ "$drift" -eq 0 ] && echo "project: already in sync"
exit 0
