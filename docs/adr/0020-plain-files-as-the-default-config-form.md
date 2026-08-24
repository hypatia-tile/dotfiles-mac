# 0020. Plain files are the default form for user-facing configuration

- Status: Accepted
- Date: 2026-08-24

Promoted to Accepted by shinokun, 2026-08-24.

## Context

Every user-facing configuration in this repository is shipped as a plain
file: the tool's own config is vendored verbatim under `config/<tool>/` and
placed by `modules/home/files.nix`. `modules/home/programs.nix` enables only
`programs.direnv` (with `nix-direnv`) and `programs.home-manager`.

That uniformity is an artifact of migration phase 2, not a standing policy.
The goal then was to move working configurations without re-expressing them
during a cutover. Two documents record it as provisional:

- `docs/design/flake-design.md` §3 maps `.config/git/` to `config/git/` with
  the note "plain files initially; `programs.git` conversion is a possible
  later cleanup";
- `docs/operations.md` §5 still lists "`programs.git` conversion" among the
  deferred cleanups.

So the question re-opens every time a tool is added, and there is no
criterion to settle it. The relevant facts:

- A `config/` payload is in the tool's native format. Upstream documentation
  applies to it directly, a diff reads as the tool's own configuration, and
  the file remains usable outside Nix.
- `programs.*` gives option-level typing and lets Nix values flow into the
  generated config — for instance the identity constants in
  `modules/common.nix`.
- The placement semantics of the plain-file route are already understood and
  written down (ADR 0006, `docs/operations.md` §2): a directory-sourced
  `xdg.configFile` makes the target a read-only store symlink, so anything
  the tool writes at runtime must be linked file-by-file (the zsh `ZDOTDIR`
  case) or kept outside the managed tree (herdr's runtime state, the nvim
  user dictionary). These are known costs, not open questions.
- Nothing in the current configuration depends on `programs.*` composition.

## Decision

Plain files under `config/`, placed by `modules/home/files.nix`, are the
**default** form for user-facing configuration.

`programs.*` is the exception, used only where Nix-side integration is
essential — where the module does something a file cannot, such as wiring
shell or session integration, or generating content from Nix values.
`programs.direnv` is the existing instance and stays.

The criterion, applied when adding anything new: *does this configuration
need a Nix value or a Nix-side integration?* If not, it is a plain file.
This is one row of the `config-change` decision table (ADR 0019).

The deferred `programs.git` conversion is **withdrawn**. Git stays as
`config/git/`, and the entry leaves the deferred list rather than becoming a
tracked issue.

## Consequences

- Adding a tool is a two-step operation with no research: drop its native
  config into `config/`, add one line to `files.nix`. Upstream documentation
  answers configuration questions directly; no Home Manager option lookup.
- A malformed configuration fails at runtime rather than at build time. This
  is accepted: it is exactly the failure mode of editing the file in place,
  which is what happened before the migration, and `preflight` cannot catch
  it either way.
- A value needed on both sides must be written twice — the identity constants
  in `modules/common.nix` are not shared with `config/git/config`. Accepted
  while the set is small. A value that genuinely needs to be in two places is
  itself the signal to reconsider `programs.*` for that one tool, which the
  criterion above already permits.
- The provisional wording in `docs/design/flake-design.md` §3 is superseded by
  this ADR. That document is not edited — ADR 0019 classifies it as a
  historical record of the migration design — so this ADR is where the
  current policy lives.
