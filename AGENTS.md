# AGENTS.md

Portable working notes for coding agents in this repository. Project rules,
scope, and the change workflow live in `CLAUDE.md`; this file collects
cross-tool operational lessons ("gotchas") learned while working here. Consult
both. Keep this tool-agnostic.

## Before you push: run the CI gates locally

CI's required checks are Nix lint (`nixfmt --check`, `statix`, `deadnix`),
`markdownlint`, `commitlint`, `gitleaks`, and the flake / system-closure build.
Run them locally before proposing a PR — the `migration-check` skill mirrors
them. Skipping this has round-tripped PRs through CI on trivial format
failures.

## markdownlint MD060 is a local-only false positive

The nixpkgs `markdownlint-cli2` is newer than CI's pinned
`markdownlint-cli2-action@v19`, so it raises rules CI does not have — notably
**MD060** (table-column-style). Ignore MD060 locally; a markdown finding is
real only if CI's version would also raise it. See `docs/operations.md` §4.

## Check the tail of files you write

The file-writing tool occasionally appends a stray closing tag (e.g.
`</content>`) to the end of a file it creates, which then breaks Nix
evaluation or lint. After writing a file, verify its tail; a quick
`grep -rn '</content>'` over the changed tree before building catches it.

## Verify runtime state empirically; process names are case-sensitive

When diagnosing system behavior (a swallowed keybinding, a daemon that
"isn't running"), confirm with a real query rather than inference — and
remember macOS process names are case-sensitive: the AeroSpace binary is
`AeroSpace`, not `aerospace`, so `pgrep -x aerospace` returns a false
negative (use `pgrep -i`, or list processes). Prefer a decisive test
(`aerospace config --get …`, quit-and-retest, or the exact observed output)
over a plausible theory, and chase asymmetries (e.g. `Option+.` works but
`Option+,` does not) to a concrete cause. The `keybinding-doctor` skill
encodes this for key-interception problems.
