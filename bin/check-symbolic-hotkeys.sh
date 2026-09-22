#!/usr/bin/env bash
# Do this machine's symbolic hotkeys still match what the repository declares?
#
# `modules/darwin/macos.nix` declares the complete AppleSymbolicHotKeys
# dictionary, and nix-darwin writes it whole at system activation. That asserts
# a state at a moment; it does not hold it. Between switches macOS writes the
# key itself — measured on 2026-09-22, adding a second input source re-enabled
# 60 and 61 (Ctrl+Space, Ctrl+Opt+Space) against a declaration of `enabled = 0`,
# so a chord the repository believes is free was taken from kitty and Emacs
# (ADR 0030).
#
# No build-time gate can see this: `nix flake check`, the closure build and the
# closure diff never read the live machine. This check does, which is the whole
# point of it — so it is **not** part of `preflight`, and CI never runs it. Run
# it after a switch, after any input-source change, and from the keybinding
# steps in the `config-change` skill.
#
# It compares against the working tree's declaration, not `main`: the question
# is whether the machine agrees with what this repository says today, which is
# also what the manual `defaults read … matches macos.nix` step compared before
# this script replaced it.
#
# IDs live-only are reported but never fail: ID 64 (Spotlight) is omitted from
# the declaration on purpose so it keeps its built-in default.
#
# Usage: bin/check-symbolic-hotkeys.sh
# Exit:  0 in sync; 1 drifted; 2 could not tell
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
  echo "check-symbolic-hotkeys: not macOS — nothing to read" >&2
  exit 2
fi

repo_root=$(cd "$(dirname "$0")/.." && pwd)

# The attribute is the `hostname` inside hosts/*.nix, not the file's basename;
# ask the flake rather than guessing (same reason as bin/running-main-check.sh).
if ! host=$(
  nix eval --raw --no-update-lock-file "${repo_root}#darwinConfigurations" \
    --apply 'cs: builtins.head (builtins.attrNames cs)' 2>/dev/null
); then
  echo "check-symbolic-hotkeys: could not read darwinConfigurations from the flake" >&2
  exit 2
fi

if ! declared=$(
  nix eval --json --no-update-lock-file \
    "${repo_root}#darwinConfigurations.${host}.config.system.defaults.CustomUserPreferences" \
    --apply 'p: p."com.apple.symbolichotkeys".AppleSymbolicHotKeys' 2>/dev/null
); then
  echo "check-symbolic-hotkeys: could not evaluate the declaration for ${host}" >&2
  exit 2
fi

if ! live=$(defaults export com.apple.symbolichotkeys - | plutil -convert json -o - -- - 2>/dev/null); then
  echo "check-symbolic-hotkeys: could not read com.apple.symbolichotkeys" >&2
  exit 2
fi

DECLARED="$declared" LIVE="$live" python3 - <<'PY'
import json
import os
import sys

declared = json.loads(os.environ["DECLARED"])
live = json.loads(os.environ["LIVE"]).get("AppleSymbolicHotKeys", {})


def on(entry):
    """macOS writes `enabled` as a boolean, nix-darwin as 0/1; normalise."""
    return bool(entry.get("enabled", False))


def params(entry):
    value = entry.get("value")
    if not isinstance(value, dict):
        return None
    return value.get("parameters")


drifted = []
for hotkey_id in sorted(declared, key=int):
    want = declared[hotkey_id]
    if hotkey_id not in live:
        drifted.append(
            f"{hotkey_id}: absent from the live domain, declared "
            f"enabled={int(on(want))} — activation writes the dictionary whole, "
            "so an absent declared ID means something rewrote it"
        )
        continue
    got = live[hotkey_id]
    if on(want) != on(got):
        drifted.append(
            f"{hotkey_id}: declared enabled={int(on(want))}, live enabled={int(on(got))}"
        )
        continue
    want_params, got_params = params(want), params(got)
    if want_params is not None and got_params is not None and want_params != got_params:
        drifted.append(
            f"{hotkey_id}: declared parameters {want_params}, live {got_params}"
        )

undeclared = sorted((k for k in live if k not in declared), key=int)
if undeclared:
    print(
        "check-symbolic-hotkeys: live-only IDs (kept at their built-in default "
        "on purpose): " + ", ".join(undeclared)
    )

if drifted:
    print(f"check-symbolic-hotkeys: {len(drifted)} ID(s) drifted from the declaration:")
    for line in drifted:
        print(f"  {line}")
    print(
        "\nThe declaration is reasserted by the owner's next `darwin-rebuild "
        "switch`, or turn the shortcut off by hand in System Settings.\n"
        "See ADR 0030."
    )
    sys.exit(1)

print(f"check-symbolic-hotkeys: {len(declared)} declared IDs match the live domain")
PY
