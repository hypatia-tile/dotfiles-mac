#!/usr/bin/env bash
# Project this repository's payloads into $HOME (ADR 0026).
#
# `~/.config` is a projection of this repository, not an editing surface: each
# declared payload is copied in and made read-only, so a change can only be
# made here. What the declaration says lives in modules/payloads.nix.
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
# runtime state living beside a payload — ~/.config/zsh/.zcompdump, herdr's
# session files — is untouched by construction.
#
# Usage:
#   bin/project.sh            place payloads, prune what left the declaration
#   bin/project.sh --check    report drift and exit non-zero; changes nothing
#
# Exit: 0 in sync (or applied); 1 drift found in --check, or a refusal; 2 error.
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
decl="$repo_root/modules/payloads.nix"
manifest="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-mac/projected"

check_only=false
[ "${1:-}" = "--check" ] && check_only=true

# Paths this script needs in order to run at all, and therefore cannot place.
# ~/.config/nix is the one that proved this: `nix eval` reads the declaration
# below, and the experimental features it needs are enabled by the user
# nix.conf. Projecting it made this script unable to read its own declaration —
# and the failure arrives *after* Home Manager has released the path, so the
# payload ends up neither placed nor linked. Refusing here rather than in a
# comment, because a comment cannot fail a build.
SELF_DEPENDENCIES=".config/nix"

[ -f "$decl" ] || { echo "project: no declaration at $decl" >&2; exit 2; }

# `target<TAB>source<TAB>mode`, one payload per line.
declared=$(
  nix eval --json -f "$decl" 2>/dev/null |
    jq -r 'to_entries[] | "\(.key)\t\(.value.source)\t\(.value.mode)"' |
    sort
) || {
  echo "project: cannot evaluate $decl" >&2
  echo "  If nix reports that 'nix-command' is disabled, ~/.config/nix/nix.conf" >&2
  echo "  is missing. Recover with:" >&2
  echo "    NIX_CONFIG='experimental-features = nix-command flakes' $0" >&2
  exit 2
}

for self in $SELF_DEPENDENCIES; do
  if printf '%s\n' "$declared" | cut -f1 | grep -qxF "$self"; then
    echo "project: refusing to project $self — this script depends on it" >&2
    echo "  Placing it would make this script unable to run, at the point where" >&2
    echo "  Home Manager has already released the path. Keep it in files.nix." >&2
    exit 2
  fi
done

placed=""
[ -f "$manifest" ] && placed=$(sort "$manifest")

drift=0
note() { if $check_only; then echo "DRIFT: $*"; else echo "$*"; fi; }

# --- remove what left the declaration ---------------------------------------
# Only paths this script recorded. Anything else in those directories was put
# there by something else and is none of our business.
while IFS= read -r target; do
  [ -n "$target" ] || continue
  if ! printf '%s\n' "$declared" | cut -f1 | grep -qxF "$target"; then
    # A payload can leave the declaration two ways: retired, or handed back to
    # Home Manager. In the second case Home Manager has already placed a store
    # symlink at the target by the time this runs (the activation hook is
    # ordered after linkGeneration), and deleting it would undo a placement
    # this script does not own. Drop it from the manifest instead.
    if readlink "$HOME/$target" 2>/dev/null | grep -q '^/nix/store/'; then
      note "release $target (Home Manager owns it again)"
      continue
    fi
    drift=1
    note "prune $target (left the declaration)"
    if ! $check_only; then
      chmod -R u+w "$HOME/$target" 2>/dev/null || true
      rm -rf "${HOME:?}/$target"
    fi
  fi
done <<< "$(printf '%s\n' "$placed")"

# --- place what the declaration asks for ------------------------------------
new_manifest=""
while IFS=$'\t' read -r target source mode; do
  [ -n "$target" ] || continue
  src="$repo_root/$source"
  dst="$HOME/$target"
  new_manifest+="$target"$'\n'

  [ -e "$src" ] || { echo "project: missing source $src" >&2; exit 2; }

  # A target we did not place is never overwritten. Back it up and say so.
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if ! printf '%s\n' "$placed" | grep -qxF "$target"; then
      drift=1
      note "backup $dst (exists but was not placed by this script)"
      if ! $check_only; then
        mv "$dst" "$dst.bak-$(date +%Y%m%d%H%M%S)"
      fi
    fi
  fi

  case "$mode" in
    link)
      if [ "$(readlink "$dst" 2>/dev/null || true)" != "$src" ]; then
        drift=1
        note "link $target -> $source"
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
printf '%s' "$new_manifest" | sed '/^$/d' | sort > "$manifest"
[ "$drift" -eq 0 ] && echo "project: already in sync"
exit 0
