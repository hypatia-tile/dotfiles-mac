#!/usr/bin/env python3
"""Report plugin pins that moved alongside unrelated changes (#98).

Called from the Docs & commit hygiene job when lazy-lock.json is one of
several files a pull request touches. Distinguishes the two ways the lock can
change:

  the pin set is identical, commits moved  -> a `:Lazy update` rode along
  the pin set gained or lost an entry      -> a plugin was added or removed,
                                              which belongs with the Lua change
                                              that declares it

Prints a warning annotation for the first and exits 0 either way: the judgement
of whether a deliberate pin update belongs in this branch is the author's.
"""

import json
import subprocess
import sys


def read(ref: str, path: str) -> dict:
    out = subprocess.run(
        ["git", "show", f"{ref}:{path}"],
        capture_output=True, text=True, check=True,
    ).stdout
    return json.loads(out)


def main() -> int:
    base_ref, lock = sys.argv[1], sys.argv[2]
    base = read(base_ref, lock)
    with open(lock) as fh:
        head = json.load(fh)

    if set(base) != set(head):
        print("ok: the pin set changed, so a plugin was added or removed")
        return 0

    moved = sorted(k for k in base if base[k]["commit"] != head[k]["commit"])
    if not moved:
        print("ok: no pin moved")
        return 0

    print(
        f"::warning file={lock}::{len(moved)} plugin pins moved with nothing "
        "added or removed, alongside other changes in this pull request — "
        "which is what a stray `:Lazy update` looks like (#98). Pins should "
        "move in a commit of their own."
    )
    for k in moved:
        print(f"  {k}: {base[k]['commit'][:9]} -> {head[k]['commit'][:9]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
