# CLAUDE.md

The rules for working in this repository are in **`AGENTS.md`**, which is
tool-agnostic and is the source of truth for them (ADR 0019). Read it first;
everything below is specific to Claude Code and adds to it rather than
restating it.

@AGENTS.md

`docs/README.md` is the index of every document and skill.

## Guardrails

Two layers enforce the safety boundary mechanically, so it survives context
resets.

`bin/agent-guard.sh` is registered in `.claude/settings.json` as a
`PreToolUse` hook, and is the authoritative enforcement for every agent
(ADR 0027) — see `AGENTS.md`. It reads each shell command as shell, so it
catches `sudo` in any position and writes into the legacy repositories that a
prefix list cannot see.

The `permissions` lists in the same file are a second layer, specific to
Claude Code and unchanged since ADR 0013:

- **deny** — `darwin-rebuild switch` / `activate`, `sudo darwin-rebuild`,
  `git push`, `nix flake update`, and writes to the two archived legacy
  repositories;
- **ask** — `git commit`, which is how "commit only on explicit instruction"
  is implemented;
- **allow** — the read-only verification commands (`nix flake check`,
  `nix build`, `nix eval`, `nix store diff-closures`, `darwin-rebuild build`,
  `git` status/diff/log/ls-files/branch, `brew list`/`leaves`/`info`).

Bash-level writes to the legacy repositories still cannot be fully blocked:
a shell string is not decidable. The guard covers the common write commands,
redirection and `cd` into a legacy repository; the hard rules in `AGENTS.md`
cover the rest.

## Skills

Procedures live in `.claude/skills/<name>/SKILL.md` and Claude Code surfaces
them automatically from their frontmatter — they are not listed here, because
an index that has to be maintained in an always-loaded file goes stale.
`docs/README.md` has the list with one line each.

**Adding a skill requires a `.gitignore` change.** Repository-workflow skills
are tracked through an allowlist (`.claude/skills/*` is ignored, with a
`!.claude/skills/<name>` exception per tracked skill) so that a skill an
agent creates for itself and skill-manager artifacts stay out of the
repository. The owner's user-scope skills are not these: they live in
`config/agents/skills/` and reach `~/.claude/skills` through the projector
(ADR 0028; see `AGENTS.md`).
A new skill that is not allowlisted is silently untracked — it works here and
is absent from every clone, with `git status` clean throughout.
`bin/check-skills.sh` is what makes that fail instead, in CI's always-on job
and in `preflight`.

It also needs the `.codex/skills/<name>` symlink `AGENTS.md` describes, for
the same reason: without it the skill reaches Claude Code and no other agent,
and nothing says so. `.codex/skills` is tracked normally rather than through
an allowlist, so a skill an agent drops there shows up in `git status`.
