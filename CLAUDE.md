# dotfiles-mac

The consolidated macOS configuration, previously split across
`~/github/dotfiles` (symlink-based) and `~/github/nix-darwin` (flake). It is a
single Nix flake: nix-darwin for the system layer, Home Manager (as a
nix-darwin module) for everything user-facing. Since the 2026-07-14 cutover
(ADR 0015) this repository is the live single source of truth; ADR 0018
records the post-cutover finalization. See `docs/requirements.md` and
`docs/adr/` for the governing decisions.

## Hard rules

- **Never run `darwin-rebuild switch` or any activation command.** Your work is
  build-only (`nix flake check`, `darwin-rebuild build`, closure diff);
  applying is the owner's manual `darwin-rebuild switch` step
  (`docs/operations.md` §1, ADR 0003, ADR 0015).
- **Never commit or push automatically.** Prepare changes and a proposed
  Conventional Commit message; commit only when explicitly instructed, push
  never (the owner pushes).
- **Source repositories are read-only:** `~/github/dotfiles` and
  `~/github/nix-darwin` are archived rollback material (ADR 0010, ADR 0018) and
  must never be modified. Do not run their `bin/dot-link.sh`.
- **No secrets in this repository**, ever (ADR 0009). During discovery, record
  secret-bearing paths by filename only; never read their contents.
- All repository artifacts (docs, code, comments, commit messages) are written
  in **English**. Conversation with the owner may be in Japanese.

## Workflow

- Cross-tool operational gotchas (run the CI lint gates locally before pushing,
  the markdownlint MD060 false positive, verify runtime state empirically) live
  in `AGENTS.md` — consult it alongside these rules.
- Work on short-lived feature branches off `main`; Conventional Commits.
- ADRs live in `docs/adr/NNNN-slug.md` (MADR-lite). New ADRs always start with
  `Status: Proposed`; only the owner promotes them to Accepted. Use the
  `adr-new` skill.
- Verification uses the `migration-check` skill: it mirrors the required CI
  gates (nixfmt/statix/deadnix, markdownlint) and builds; never switches. Run
  it before pushing.
- Other repository skills: `ops-qa` (answer operations questions from the
  docs), `ship-pr` (push-wait → PR → CI watch), `nvim-bump` (nvim-config
  edit + pinned-input bump per ADR 0014), `keybinding-doctor` (diagnose a
  macOS key/chord that is swallowed or misbehaving).
- `flake.lock` updates land as dedicated commits: the weekly
  `update-flake-lock` Action opens PRs and merging is always manual
  (ADR 0011, ADR 0012). Build and check invocations still pass
  `--no-update-lock-file` so they never mutate the lock as a side effect, and
  ad-hoc `nix flake update` stays denied in tooling.

## Layout

- `docs/requirements.md` — requirements, mapped to ADRs
- `docs/adr/` — architecture decision records
- `docs/discovery/` — read-only inventory of the current machine state,
  with per-item migration verdicts made by the owner
- `docs/runbook.md` — cutover and rollback procedures
- `docs/operations.md` — post-cutover operations guide (change workflow,
  HM placement semantics, CI behavior, known quirks)
