#!/usr/bin/env bash
# No secret ever enters the repository (ADR 0009), by the gitleaks the check
# devShell pins (ADR 0032) and its default rules.
#
# Outside the file contract of bin/lib/check.sh, like check-commits.sh: it
# reads git content, not changed files. It has no scope and no --applies —
# every commit concerns it.
#
# The history is what HEAD reaches, not every ref (gitleaks' default): CI
# fetches every branch, and a secret on one must not fail another's run.
#
# Usage: nix develop -c bin/check-secrets.sh
#          every commit reachable from HEAD
#        nix develop -c bin/check-secrets.sh --staged
#          the staged diff (the pre-commit hook)
# Exit:  0 none found; 1 a secret found; 2 usage error, or gitleaks failed
set -uo pipefail

usage() {
  echo "usage: $(basename "$0") [--staged]" >&2
  exit 2
}

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "$(basename "$0"): 'gitleaks' is not on PATH; run it as: nix develop -c $0" >&2
  exit 2
fi

case $# in
  0) mode=(--log-opts=HEAD) ;;
  1) [[ $1 == --staged ]] || usage; mode=(--staged) ;;
  *) usage ;;
esac

cd "$(dirname "$0")/.." || exit 2
# gitleaks exits 1 both on a finding and on a failure to run; a distinct code
# for findings keeps the two apart.
gitleaks git "${mode[@]}" --exit-code 3 --redact --verbose --no-banner .
case $? in
  0) exit 0 ;;
  3) exit 1 ;;
  *) exit 2 ;;
esac
