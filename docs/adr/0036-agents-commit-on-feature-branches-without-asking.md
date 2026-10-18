# 0036. Agents commit on feature branches without asking

- Status: Accepted
- Date: 2026-10-17

## Context

ADR 0008 lets an agent commit only on the owner's explicit instruction.
That rule is implemented in two places:

- `.claude/settings.json` lists `git commit` under `ask` (ADR 0013);
- `bin/agent-guard.sh` answers `ask` for every `git commit` (ADR 0027), and
  `bin/check-agent-guard.sh` holds it there.

When the rule was made, the confirmation was the only check a commit
passed through. Since then, a commit has gained checks of its own:

- the Git hooks run every gate on each commit and push (ADR 0032);
- `bin/check-branch.sh` refuses a commit on `main` (#209);
- agent-guard refuses every way of committing without the hooks (#199).

In practice the confirmation has become a step that adds nothing. By the time
an agent commits, the owner has usually seen the change in the conversation.
The commit is local: it can be amended, reset or dropped, and nobody but the
owner sees it until it is pushed. Pushing is what publishes, and pushing
already stays the owner's. The cost is real, though: work stops at every
commit until the owner answers. #254 records the problem and what the owner
agreed on 2026-10-17.

## Decision

- **An agent commits on a feature branch without asking.** Commits still go
  through the hooks, which an agent never bypasses (ADR 0032). The hooks
  still refuse a commit on `main`.
- **What stays the owner's is unchanged:** pushing, merging,
  `darwin-rebuild switch`, activation and `sudo`.
- **Every commit is reported.** The next report to the owner names the
  branch, each new commit's short hash and subject, and says that nothing
  has been pushed. A commit made silently is a reporting error, as a merge
  described as applied is.
- **Implementation:**
  - `.claude/settings.json` moves `Bash(git commit:*)` from `ask` to `allow`.
    Removing it from `ask` would not be enough, because Claude Code still
    asks about a command it does not allow.
  - `bin/agent-guard.sh` stops answering `ask` for `git commit`. Its
    refusals of commits that skip the hooks stay.
  - `bin/check-agent-guard.sh` expects a plain commit to be allowed.
  - `AGENTS.md`, `CLAUDE.md`, `ship-pr`, `config-change` and `adr-new` say
    the same thing.
- **Scope: this repository.** The guard and the settings file are
  registered only here. Whether the rule also holds in other repositories,
  through the user-scope instruction file, is #193's question.

This supersedes **ADR 0008's clause that an agent commits only on explicit
instruction**, together with the `ask` rows that implement it: ADR 0013's
`ask` list, and the "commit only on instruction" row of ADR 0027's table. The
rest of those ADRs stands.

## Consequences

- An agent can carry a change through to a commit, or a series of commits,
  without a pause at each one. #255 builds on that: an issue taken to a stack
  of committed branches, which the owner then pushes.
- The owner reviews at a later point: the commits on the branch before
  pushing, and the PR before merging. A commit the owner disagrees with is
  amended or dropped before the push. That is cheap, but only if the report
  names the commit.
- The protection now rests on the hooks being installed. A clone without
  `core.hooksPath` runs no gates, and an agent committing there is not
  checked. `ship-pr` already runs `bin/hooks-health.sh` before a push; an
  agent should run it before its first commit in a session, too.
- cursor-agent loses the confirmation along with Claude Code, because it
  reads the same guard and settings file. Codex never had it: it rejects an
  `ask` answer, so the guard already left a Codex commit to Codex's own
  approval flow (ADR 0027), and that is unchanged.
