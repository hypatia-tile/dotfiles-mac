# 0028. Deploy user-scope agent skills from this repository

- Status: Proposed
- Date: 2026-09-14

## Context

The owner's personal, user-scope skills — `clangd-check`, `github-english`,
`grilling`, `handoff`, `step-review`, `step-start` — live in
`hypatia-tile/skills`. `~/.claude/skills` is a single symlink into that
checkout, created by `nix run .#install`, as decided by that repository's ADR
0001. The owner wants agent configuration in one repository, and wants it to
serve agents other than Claude Code; `codex` and `cursor-agent` are declared in
`modules/home/packages.nix`.

**ADR 0001 there rested on two premises, and one no longer holds.** It
rejected Home Manager because Home Manager here has exactly one owner — still
true, and still respected, since nothing below uses it. It rejected placement
from this repository because "the house pattern for config in its own
repository is store-pinned and read-only", so every skill edit would need a
commit, a lock bump and a switch. That stopped being the house pattern: ADR
0021 moved payloads to working-tree links, and ADR 0026 replaced them with a
projector that places read-only copies *and*, per path, a `link` for files a
tool must write back into the repository. A skill is exactly that — it is
prompt text the agent itself rewrites mid-session. ADR 0001 also said its own
pattern should be taken up by other repositories "by those repositories' own
ADRs"; this is that ADR.

**Where each agent reads user-scope skills** was established from the pinned
binaries and the machine, not from documentation:

- **Claude Code 2.1.266** reads `~/.claude/skills`. `.agents/skills` appears in
  the binary only inside a feature that imports another agent's configuration,
  and a skill present in `~/.agents/skills` is not surfaced in a session.
- **Codex 0.154.0** reads `$CODEX_HOME/skills`, i.e. `~/.codex/skills`, and
  **writes into it**: its bundled skills live in `~/.codex/skills/.system`, and
  its skill installer installs into `~/.codex/skills/<name>`. Its loader
  ignores, without an error, a skill whose required field is missing, empty or
  too long. Its skill-creator requires names of lowercase letters, digits and
  hyphens, under 64 characters.
- **cursor-agent 2026.08.31** treats `.claude/skills`, `.codex/skills`,
  `.agents/skills` and `.cursor/skills` all as skill paths.

No single directory reaches all three. `~/.agents/skills` does not reach Claude
Code, and `~/.codex/skills` cannot be handed to this repository whole without
taking Codex's `.system` with it — the granularity rule `modules/payloads.tsv`
states, and the defect #94 was.

**Two projector hazards were measured before deciding.**

- With today's `~/.claude/skills` symlink still in place, a projector run that
  places `.claude/skills/grilling` resolves the target *through* the symlink.
  It moved the real `grilling/` inside the `hypatia-tile/skills` working tree
  to `grilling.bak-<timestamp>`, planted a link beside it, left
  `~/.claude/skills` untouched, and exited 0. The projector runs on every
  `darwin-rebuild switch` (`home.activation.projectPayloads`), so after a merge
  this would fire on the owner's next, unrelated switch.
- The projector links to `$repo_root/<source>`, where `repo_root` is the
  directory of the script that ran. Run by hand from a `git worktree`, it
  repoints every link into the worktree, which tools remove when they are done.
  With one link today the exposure is small; with a dozen skill links it is
  every agent's skills at once.

`grilling` and `handoff` derive from `mattpocock/skills` (MIT), whose licence
requires the copyright and permission notice in every copy. This repository is
public and has no licence of its own.

## Decision

**User-scope agent skills live in this repository, at
`config/agents/skills/<name>/SKILL.md`**, and are placed by the projector. The
directory is named for the consumer, not a tool: ADR 0020's `config/<tool>/`
convention has no tool to name when three agents read the same file, and
`agents` matches the `.agents/skills` name the agents already share.

**They are copied in, not imported with history.** The copy records neither
the source commits nor their authorship. `hypatia-tile/skills` is then
**archived and never deleted**: it becomes the only place that history exists.
Its README gains a pointer to this ADR before archiving; no ADR is added there.

**`config/agents/skills/NOTICE.md` carries the `mattpocock/skills` notice** for
`grilling` and `handoff`. This repository's own licence is not decided here.

**Each skill is linked per path into two agents.** `modules/payloads.tsv`
declares, for every skill, `.claude/skills/<name>` and `.codex/skills/<name>`
as `link` entries to `config/agents/skills/<name>`. This applies ADR 0026's
`link` criterion without changing it. cursor-agent is in the verification
scope but not a target: it already reads both paths, and a
`~/.cursor/skills` target would only add a third copy of each skill to its view.
No directory-level entry is declared, because both target directories hold
entries this repository does not own.

**No skill manager places skills.** `~/.agents/skills/find-skills`, installed
by `npx skills`, is removed, and skills are not installed by such tools again:
their purpose is to write unmanaged copies into the agents' directories, which
is what a single source rules out.

**Skills follow the checkout.** A link resolves into this working tree, so a
skill edited on a feature branch reverts in every session when another branch
is checked out, and a branch created before this change has no
`config/agents/skills` at all. This is accepted, as it was for `nvim`; the
cutover deletes local branches that predate it.

**The projector refuses both measured hazards.** It exits 2, naming the cause,
when a target's parent path contains a symlink, and when it would place
anything from a worktree other than the main one. `--check` and `--validate`
still run anywhere.

**`bin/check-skills.sh` covers the new failure modes**, all silent at run time:
it validates `.claude/skills` and `config/agents/skills`; fails a user-scope
skill missing either `payloads.tsv` entry; fails a name used in both roots;
and fails a name that is not lowercase letters, digits and hyphens under 64
characters. A description length limit is not encoded, because Codex's value
was not established. A skill referencing a skill that does not exist is not
checked, for the false-positive reason recorded in `hypatia-tile/skills#5`.

**Rules and procedure are split as ADR 0019 prescribes.** `AGENTS.md` gains the
rules that hold whenever a skill is touched — an edit is live everywhere at
once, scope is decided before a skill is added, a copied skill gets a
`NOTICE.md` entry, no secrets or personal paths. The `config-change` skill's
table gains the row for adding one.

**Project-scope skills stay in `.claude/skills/`**, where Claude Code and
cursor-agent read them, and Codex reaches them through per-skill relative links
at its repository skill path. *TBD: that path — `.codex/skills` or
`.agents/skills` — is measured before the links are added; if it is
`.agents/skills`, the `.gitignore` entry for `.agents/` is narrowed.*

**Verified before `hypatia-tile/skills` is archived.** In a new Claude Code
session and a new Codex session, `/skills` must list all six user-scope skills,
each once; a missing skill blocks the archive. Codex not loading `handoff`,
whose frontmatter carries Claude-only keys, and cursor-agent listing a skill
twice are recorded as issues and do not block.

This **supersedes `hypatia-tile/skills` ADR 0001**: deployment by
`nix run .#install` and the single directory symlink are retired, and so is
that repository as the source of truth. Its criterion — pin into the store for
reproducibility, link the working tree for content edited far more often than
the machine is rebuilt — is the one applied here.

## Consequences

- One repository holds agent configuration, and a new machine gets its skills
  from the clone and a projector run, with no separate install step.
- Editing a skill stays live in every session, as under ADR 0001. Adding one
  now costs a directory, two `payloads.tsv` lines and a projector run, and
  `bin/check-skills.sh` fails the change that forgets a line.
- Codex gains the owner's skills for the first time. cursor-agent may show each
  skill twice, since it reads both targets; whether it deduplicates by name is
  measured at cutover.
- Checking out an old branch in this repository changes, or removes, the skills
  of every running agent session. The projector does not detect a dangling
  link.
- A skill an agent creates in `~/.claude/skills/<new>` is a real directory
  beside the links, not a file in this repository, and nothing reports it.
  Writes to an *existing* skill land in the working tree and show in
  `git status`, as they did in `hypatia-tile/skills`.
- The four original skills were MIT-licensed there. Here they sit in a public
  repository without a licence, so others lose the permission; the owner's own
  use is unaffected.
- The history of all six skills survives only in the archived repository, which
  is why archiving is never followed by deletion.
