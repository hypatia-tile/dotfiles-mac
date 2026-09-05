#!/usr/bin/env bash
# Is this machine running `main`?
#
# ADR 0022 allows switching from a feature branch, including from a dirty
# working tree, so that a change can be tried before it is shipped. The
# invariant it keeps is only about the resting state: once a change is merged,
# the machine is switched from `main`. This check is what makes that
# mechanically verifiable instead of remembered.
#
# It builds `main` specifically — not the working tree, which is what a bare
# `nix build .#…` would use — and compares the result with the running system.
# Equal means the machine is running `main`.
#
# Not part of `preflight`: that runs while being on a branch is expected, where
# this check would fire on every ordinary run. Use it after merging, which is
# where the `ship-pr` skill names it.
#
# Usage: bin/running-main-check.sh
# Exit:  0 running `main`; 1 drifted; 2 could not tell
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
flake="git+file://${repo_root}?ref=refs/heads/main"

# Ask the flake for the host rather than deriving it from a filename: the
# attribute is the `hostname` inside hosts/*.nix ("Kazukis-MacBook-Air"), not
# the file's basename ("kazukis-macbook-air"), and guessing gets it wrong.
if ! host=$(
  nix eval --raw --no-update-lock-file "${flake}#darwinConfigurations" \
    --apply 'cs: builtins.head (builtins.attrNames cs)' 2>/dev/null
); then
  echo "running-main-check: cannot evaluate darwinConfigurations on main" >&2
  exit 2
fi

running=$(readlink /run/current-system || true)
if [ -z "$running" ]; then
  echo "running-main-check: cannot read /run/current-system" >&2
  exit 2
fi

# `git+file://…?ref=refs/heads/main` pins the evaluation to the committed
# branch, so an experimental switch in progress does not make this pass.
if ! built=$(
  nix build "${flake}#darwinConfigurations.${host}.system" \
    --no-link --print-out-paths --no-update-lock-file 2>/dev/null
); then
  echo "running-main-check: could not build ${host} from main" >&2
  exit 2
fi

if [ "$running" = "$built" ]; then
  echo "running-main-check: PASS — the machine is running main"
  echo "  $running"
  exit 0
fi

echo "running-main-check: DRIFTED — the machine is not running main" >&2
echo "  running: $running" >&2
echo "  main:    $built" >&2
echo >&2
echo "Expected while a change is still being tried. After a merge it means the" >&2
echo "switch from main has not happened yet:" >&2
echo "  sudo darwin-rebuild switch --flake .#${host}" >&2
exit 1
