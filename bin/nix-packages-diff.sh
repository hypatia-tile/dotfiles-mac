#!/usr/bin/env bash
# What a nix-packages change would do to this host, before it merges there.
#
# Since ADR 0037 the packages, Homebrew and fonts are declared in
# hypatia-tile/nix-packages. Its CI builds its modules in a minimal system,
# but only this repository can say what a change there does to this host
# (#310, stage 4). This builds the host twice, with the locked nix-packages
# and with a local checkout through --override-input, and prints the
# difference: the closure diff, and the Brewfile diff, since a cask or brew
# shows in the closure only as a changed Brewfile.
#
# Neither diff is pass or fail. Like the closure diff in the `preflight`
# skill, it needs a reader, who checks that it shows the change under review
# and nothing else.
#
# The checkout is read as a path: flake, so uncommitted and untracked files
# count. flake.lock is never written. Build only; nothing is switched or
# activated (ADR 0003).
#
# Usage: bin/nix-packages-diff.sh [CHECKOUT]
#          CHECKOUT  the nix-packages checkout; default: the one beside this
#                    repository's, as ghq places both under hypatia-tile/
# Exit:  0 both built, diffs printed; 1 a build failed; 2 usage or setup error
set -uo pipefail

[[ $# -le 1 && ${1-} != -* ]] || {
  echo "usage: $(basename "$0") [CHECKOUT]" >&2
  exit 2
}

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root" || exit 2

checkout=${1:-${repo_root%/*}/nix-packages}
if [[ ! -f $checkout/flake.nix ]]; then
  echo "$(basename "$0"): no flake.nix in $checkout" >&2
  exit 2
fi
checkout=$(cd "$checkout" && pwd)

# Ask the flake for the host, as running-main-check.sh does: the attribute is
# the hostname inside hosts/*.nix, not the file's name.
if ! host=$(nix eval --raw --no-update-lock-file .#darwinConfigurations \
  --apply 'cs: builtins.concatStringsSep "\n" (builtins.attrNames cs)'); then
  echo "$(basename "$0"): could not evaluate darwinConfigurations" >&2
  exit 2
fi
if [[ $host == *$'\n'* ]]; then
  echo "$(basename "$0"): more than one host; this script handles one" >&2
  exit 2
fi
attr=.#darwinConfigurations.$host

locked=(--no-update-lock-file)
local_np=(--no-write-lock-file --override-input nix-packages "path:$checkout")

out=$(mktemp -d "${TMPDIR:-/tmp}/nix-packages-diff.XXXXXX") || exit 2
trap 'rm -rf "$out"' EXIT

echo "==> build $host with the locked nix-packages"
nix build "$attr.system" "${locked[@]}" -o "$out/locked" || exit 1
echo "==> build $host with $checkout"
nix build "$attr.system" "${local_np[@]}" -o "$out/local" || exit 1

old=$(readlink "$out/locked")
new=$(readlink "$out/local")
echo
echo "locked: $old"
echo "local:  $new"
if [[ $old == "$new" ]]; then
  echo "same store path: the change does nothing to this host"
  exit 0
fi

echo
echo "==> closure diff"
nix store diff-closures "$old" "$new"

# Evaluated before printing, so that the override's "not writing modified lock
# file" warning does not land inside the diff; it is shown only on failure.
brewfile() {
  nix eval --raw "$attr.config.homebrew.brewfile" "$@" 2>"$out/eval.log" ||
    { cat "$out/eval.log" >&2; return 1; }
}
old_brewfile=$(brewfile "${locked[@]}") || exit 1
new_brewfile=$(brewfile "${local_np[@]}") || exit 1

echo
echo "==> Brewfile diff"
diff -u --label locked --label local \
  <(printf '%s\n' "$old_brewfile") <(printf '%s\n' "$new_brewfile") &&
  echo "(none)"
exit 0
