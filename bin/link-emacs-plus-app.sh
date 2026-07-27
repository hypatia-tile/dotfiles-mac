#!/usr/bin/env bash
# Copy the emacs-plus GUI apps into /Applications.
#
# emacs-plus is a Homebrew *formula*, so it builds Emacs.app inside its Cellar
# instead of installing to /Applications the way the old emacs-app cask did. A
# symlink there integrates poorly with Spotlight, Launchpad, and the Dock, so
# the emacs-plus caveats recommend copying the apps in. The copy is
# version-pinned and goes stale, so re-run this after every
# `brew reinstall emacs-plus@30` (see docs/operations.md).
#
# Usage: bin/link-emacs-plus-app.sh [formula]   (default: emacs-plus@30)
set -euo pipefail

formula="${1:-emacs-plus@30}"
prefix="$(brew --prefix)/opt/${formula}"

if [ ! -d "${prefix}" ]; then
  echo "error: ${formula} not found at ${prefix} (is it installed?)" >&2
  exit 1
fi

for app in "Emacs.app" "Emacs Client.app"; do
  src="${prefix}/${app}"
  dst="/Applications/${app}"
  if [ ! -d "${src}" ]; then
    echo "skip: ${src} does not exist" >&2
    continue
  fi
  # rm -rf removes a stale symlink or a previous copy without touching the
  # Cellar source; cp -R then places a fresh, Spotlight-indexable copy.
  rm -rf "${dst}"
  cp -R "${src}" "${dst}"
  echo "linked: ${dst} (copied from ${src})"
done
