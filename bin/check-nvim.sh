#!/usr/bin/env bash
# The nvim payload starts cleanly, with the Neovim the machine runs: the
# nightly overlay the hosts apply, from the check devShell's nvim shell
# (ADR 0032). config/nvim/bin/check holds the check itself — it restores the
# plugins to lazy-lock.json and fails on anything a headless startup prints.
#
# Any file of the payload can break startup, so any change to one runs it.
#
# Usage: nix develop .#nvim -c bin/check-nvim.sh [--applies] [FILE...]
#        (the contract is in bin/lib/check.sh; FILE only decides whether the
#        whole check runs)
set -euo pipefail
# shellcheck source=lib/check.sh source-path=SCRIPTDIR
. "$(dirname "$0")/lib/check.sh"

scope 'config/nvim/*'
check_gate "$@"

need nvim deno
config/nvim/bin/check || exit 1
