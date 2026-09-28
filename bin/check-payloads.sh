#!/usr/bin/env bash
# The payload declaration is one the projector can act on (#91):
# `bin/project.sh --validate` reads modules/payloads.tsv and the sources it
# names, and no $HOME path. Caught here, a declaration the projector would
# reject is caught while the old placement is intact, rather than in the
# activation window where the payload is neither linked nor placed.
#
# The scope is read from the declaration itself, so a rename or deletion under
# any declared source runs this, and a new source is in scope once declared.
#
# Usage: bin/check-payloads.sh [--applies] [FILE...]
#        (the contract is in bin/lib/check.sh)
set -euo pipefail
# shellcheck source=lib/check.sh source-path=SCRIPTDIR
. "$(dirname "$0")/lib/check.sh"

scope modules/payloads.tsv bin/project.sh
while IFS=$'\t' read -r _ source _; do
  [[ -n $source ]] && scope "$source" "$source/*"
done < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' modules/payloads.tsv)
check_gate "$@"

# The projector exits 2 for a declaration it rejects; to the contract that is a
# finding, not a check that could not run.
bin/project.sh --validate || exit 1
