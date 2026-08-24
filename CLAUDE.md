# CLAUDE.md

The rules for working in this repository are in **`AGENTS.md`**, which is
tool-agnostic and is the source of truth for them (ADR 0019). Read it first;
everything below is specific to Claude Code and adds to it rather than
restating it.

@AGENTS.md

`docs/README.md` is the index of every document and skill.

## Guardrails

`.claude/settings.json` enforces the safety boundary mechanically, so it
survives context resets (ADR 0013):

- **deny** — `darwin-rebuild switch` / `activate`, `sudo darwin-rebuild`,
  `git push`, `nix flake update`, and writes to the two archived legacy
  repositories;
- **ask** — `git commit`, which is how "commit only on explicit instruction"
  is implemented;
- **allow** — the read-only verification commands (`nix flake check`,
  `nix build`, `nix eval`, `nix store diff-closures`, `darwin-rebuild build`,
  `git` status/diff/log/ls-files/branch, `brew list`/`leaves`/`info`).

Bash-level writes to the legacy repositories cannot be fully pattern-blocked;
the deny rules cover the realistic paths and the hard rules in `AGENTS.md`
cover the rest.

## Skills

Procedures live in `.claude/skills/<name>/SKILL.md` and Claude Code surfaces
them automatically from their frontmatter — they are not listed here, because
an index that has to be maintained in an always-loaded file goes stale.
`docs/README.md` has the list with one line each.

**Adding a skill requires a `.gitignore` change.** Repository-workflow skills
are tracked through an allowlist (`.claude/skills/*` is ignored, with a
`!.claude/skills/<name>` exception per tracked skill) so that personal skills
in `~/.claude/skills` and skill-manager artifacts stay out of the repository.
A new skill that is not allowlisted is silently untracked.
