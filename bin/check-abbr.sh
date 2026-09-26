#!/usr/bin/env bash
# Validate the zsh-abbr abbreviations payload, config/zsh/abbreviations.
#
# Every failure this catches is a silent one. zsh-abbr loads that file itself at
# every shell start, and its loader executes only lines whose first word is
# `abbr`, ignoring everything else without a word — so a misspelled keyword, a
# stray `abbr add`, or a quoting slip is not an error, it is an abbreviation that
# simply never exists. The mechanism this replaced failed the same way for
# months: `v` was declared and never applied, and nobody could tell.
#
# So the check does not read the file and reason about it. It loads it with the
# real plugin in a sandbox and asks the plugin what it got:
#
#   1. structure   every content line is `abbr "<name>"="<expansion>"`
#   2. unique      no name is declared twice (the later one would win silently)
#   3. wired       modules/abbr.zsh points ABBR_USER_ABBREVIATIONS_FILE here and
#                  modules/payloads.tsv projects the file — either one stale and
#                  the abbreviations are declared but never read
#   4. loaded      `abbr list` after a real load equals the declaration, name
#                  for name and expansion for expansion
#   5. --commands  every expansion starts with something runnable *here*
#
# Step 5 is opt-in because only this machine knows what is installed: the CI
# runner has no docker, tmux or nvim, so it runs steps 1-4 and `preflight` adds
# --commands locally. It is the check that was missing when `dc` expanded to
# `docker-compose`, a binary modules/home/packages.nix deliberately does not
# install, and when ten kubectl abbreviations named one this machine never had.
#
# Usage: bin/check-abbr.sh [--commands]
# Exit:  0 sound; 1 a check failed; 2 the plugin could not be obtained
#
# The plugin comes from the Home Manager profile when this runs on the machine,
# and from the flake's own pinned nixpkgs otherwise, so CI checks the version
# the machine gets. nixpkgs marks zsh-abbr unfree (CC-BY-NC-SA-4.0 and HL3),
# which modules/darwin/nix.nix allows for the system but a bare `nix build` does
# not, hence NIXPKGS_ALLOW_UNFREE and --impure. $ABBR_PLUGIN overrides both.
set -euo pipefail

ABBREVIATIONS=config/zsh/abbreviations
MODULE=config/zsh/modules/abbr.zsh
PAYLOADS=modules/payloads.tsv

check_commands=false
case "${1:-}" in
  "") ;;
  --commands) check_commands=true ;;
  *) echo "check-abbr: unknown option '$1' (expected --commands)" >&2; exit 2 ;;
esac

fail=0
err() { echo "error: $*" >&2; fail=1; }
tab=$'\t'

[[ -f $ABBREVIATIONS ]] || { echo "check-abbr: $ABBREVIATIONS not found — run from the checkout root" >&2; exit 2; }

# 1 & 2. Structure and uniqueness, by line number so the message is actionable.
declared=0
names=""
n=0
while IFS= read -r line || [[ -n $line ]]; do
  n=$((n + 1))
  [[ -z ${line//[[:space:]]/} ]] && continue
  [[ $line =~ ^[[:space:]]*# ]] && continue
  if [[ ! $line =~ ^abbr\ \"[^\"]+\"=\".+\"$ ]]; then
    err "$ABBREVIATIONS:$n: not \`abbr \"<name>\"=\"<expansion>\"\` — zsh-abbr would skip this line without a word: $line"
    continue
  fi
  name=${line#abbr \"}
  name=${name%%\"*}
  if printf '%s\n' "$names" | grep -qxF "$name"; then
    err "$ABBREVIATIONS:$n: \`$name\` is declared twice — the later one wins, silently"
  fi
  names+="$name"$'\n'
  declared=$((declared + 1))
done < "$ABBREVIATIONS"

(( declared > 0 )) || err "$ABBREVIATIONS declares nothing"

# 3. Wired up. A rename that misses either of these leaves a file that is
# maintained and never read — no error anywhere, just abbreviations that do not
# expand.
# shellcheck disable=SC2016  # the literal $ZDOTDIR is what must be in the file
grep -qF 'ABBR_USER_ABBREVIATIONS_FILE=$ZDOTDIR/abbreviations' "$MODULE" ||
  err "$MODULE does not point ABBR_USER_ABBREVIATIONS_FILE at \$ZDOTDIR/abbreviations"
grep -qxF ".config/zsh/abbreviations${tab}config/zsh/abbreviations${tab}copy" "$PAYLOADS" ||
  err "$PAYLOADS does not project $ABBREVIATIONS to .config/zsh/abbreviations as a copy"

# 4. What the plugin actually loaded.
plugin=${ABBR_PLUGIN:-}
if [[ -z $plugin ]]; then
  profile=/etc/profiles/per-user/${USER:-$(id -un)}/share/zsh/zsh-abbr/zsh-abbr.zsh
  if [[ -f $profile ]]; then
    plugin=$profile
  elif command -v nix >/dev/null 2>&1; then
    out=$(NIXPKGS_ALLOW_UNFREE=1 nix build --impure --inputs-from . --no-link \
            --print-out-paths --no-update-lock-file nixpkgs#zsh-abbr) ||
      { echo "check-abbr: could not build zsh-abbr from the pinned nixpkgs" >&2; exit 2; }
    plugin=$out/share/zsh/zsh-abbr/zsh-abbr.zsh
  else
    echo "check-abbr: no zsh-abbr — install nix or set \$ABBR_PLUGIN" >&2
    exit 2
  fi
fi
[[ -f $plugin ]] || { echo "check-abbr: $plugin is not a file" >&2; exit 2; }
command -v zsh >/dev/null 2>&1 || { echo "check-abbr: zsh not found" >&2; exit 2; }

sandbox=$(mktemp -d)
trap 'rm -rf "$sandbox"' EXIT
mkdir -p "$sandbox/config/zsh" "$sandbox/tmp"
cp "$ABBREVIATIONS" "$sandbox/config/zsh/abbreviations"

# env -i: the load must not depend on the caller's shell, and ABBR_TMPDIR keeps
# it off the live machine's $TMPDIR/zsh-abbr, which the owner's running shells
# are using for their own session state.
loaded=$sandbox/loaded
# shellcheck disable=SC2016  # $PLUGIN is expanded by the zsh below, not here
env -i \
  HOME="$sandbox" \
  XDG_CONFIG_HOME="$sandbox/config" \
  XDG_STATE_HOME="$sandbox/state" \
  TMPDIR="$sandbox/tmp" \
  ABBR_TMPDIR="$sandbox/tmp/zsh-abbr" \
  USER="${USER:-check-abbr}" \
  PATH=/usr/bin:/bin \
  ABBR_USER_ABBREVIATIONS_FILE="$sandbox/config/zsh/abbreviations" \
  PLUGIN="$plugin" \
  zsh -f -c 'source $PLUGIN; abbr list' > "$loaded" 2>"$sandbox/stderr" || {
    err "loading $ABBREVIATIONS failed:"
    sed 's/^/    /' "$sandbox/stderr" >&2
  }
[[ -s $sandbox/stderr ]] && { err "loading $ABBREVIATIONS was not silent:"; sed 's/^/    /' "$sandbox/stderr" >&2; }

# `abbr list` prints the declaration's own form without the leading keyword, so
# the two are comparable line for line.
sed -n 's/^abbr //p' "$ABBREVIATIONS" | sort > "$sandbox/want"
sort "$loaded" > "$sandbox/got"
if ! diff_out=$(diff "$sandbox/want" "$sandbox/got"); then
  err "the plugin did not load what $ABBREVIATIONS declares (< declared, > loaded):"
  printf '%s\n' "$diff_out" | sed 's/^/    /' >&2
fi

# 5. Runnable heads, on this machine only. Checked in zsh, because a zsh builtin
# is not always a bash one.
if $check_commands; then
  heads=$(sed -n 's/^abbr "[^"]*"="\([^ "]*\).*/\1/p' "$ABBREVIATIONS" | sort -u)
  while IFS= read -r head; do
    [[ -n $head ]] || continue
    # shellcheck disable=SC2016  # $1 is the head, passed as an argument below
    if ! zsh -f -c 'whence -w -- "$1" >/dev/null 2>&1' zsh "$head"; then
      err "\`$head\` does not resolve on this machine — every abbreviation expanding to it is dead. Declare it in modules/home/packages.nix or change the expansion:"
      grep -n "^abbr \"[^\"]*\"=\"$head" "$ABBREVIATIONS" | sed 's/^/    /' >&2
    fi
  done <<< "$heads"
fi

[[ $fail -eq 0 ]] || exit 1
summary="check-abbr: $declared abbreviations declared, loaded and identical"
$check_commands && summary+="; every expansion resolves here"
echo "$summary"
