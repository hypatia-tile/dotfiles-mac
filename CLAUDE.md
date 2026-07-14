# dotfiles-mac

Consolidation target for the macOS configuration previously split across
`~/github/dotfiles` (symlink-based) and `~/github/nix-darwin` (flake). The end
state is a single Nix flake: nix-darwin for the system layer, Home Manager
(as a nix-darwin module) for everything user-facing. See `docs/requirements.md`
and `docs/adr/` for the governing decisions.

## Hard rules

- **Never run `darwin-rebuild switch` or any activation command.** Verification
  is build-only (`nix flake check`, `darwin-rebuild build`, closure diff).
  Cutover is performed manually by the repository owner, gated on a dedicated
  ADR (see ADR 0003 and `docs/runbook.md`).
- **Never commit or push automatically.** Prepare changes and a proposed
  Conventional Commit message; commit only when explicitly instructed, push
  never (the owner pushes).
- **Source repositories are read-only:** `~/github/dotfiles` and
  `~/github/nix-darwin` must never be modified. Do not run their
  `bin/dot-link.sh`.
- **No secrets in this repository**, ever (ADR 0009). During discovery, record
  secret-bearing paths by filename only; never read their contents.
- All repository artifacts (docs, code, comments, commit messages) are written
  in **English**. Conversation with the owner may be in Japanese.

## Workflow

- Work on short-lived feature branches off `main`; Conventional Commits.
- ADRs live in `docs/adr/NNNN-slug.md` (MADR-lite). New ADRs always start with
  `Status: Proposed`; only the owner promotes them to Accepted. Use the
  `adr-new` skill.
- Verification uses the `migration-check` skill (build-only, never switches).
- `flake.lock` stays frozen during the migration: always pass
  `--no-update-lock-file`; `nix flake update` is denied until cutover
  (ADR 0011).

## Layout

- `docs/requirements.md` — requirements, mapped to ADRs
- `docs/adr/` — architecture decision records
- `docs/discovery/` — read-only inventory of the current machine state,
  with per-item migration verdicts made by the owner
- `docs/runbook.md` — cutover and rollback procedures
- `docs/operations.md` — post-cutover operations guide (change workflow,
  HM placement semantics, CI behavior, known quirks)
