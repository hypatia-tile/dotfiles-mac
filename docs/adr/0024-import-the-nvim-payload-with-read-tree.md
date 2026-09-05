# 0024. Import the Neovim payload with read-tree, not git subtree

- Status: Accepted
- Date: 2026-09-05

Promoted to Accepted by shinokun, 2026-09-05.

## Context

ADR 0023 decided to import `nvim-config` with `git subtree add --squash`, so
that its 188 commits are not grafted into this repository's history.

That command cannot produce a history this repository will accept. It writes
two commits: the merge commit, whose message `-m` controls, and a squash commit
whose message is generated and not configurable:

```text
Squashed 'config/nvim/' content from commit f8fd233

git-subtree-dir: config/nvim
git-subtree-split: f8fd233fd939e86e9bc35ce1e1395a13c2e595de
```

commitlint rejects it — `subject may not be empty`, `type may not be empty` —
so the *Docs & commit hygiene* job fails. Passing `-m` does not reach that
commit; this was checked rather than assumed.

So two accepted decisions were in conflict: ADR 0023's named command, and the
Conventional Commits requirement of ADR 0008 enforced by ADR 0012's CI.

## Decision

Import with `git read-tree --prefix=config/nvim -u FETCH_HEAD`, committed as a
single ordinary Conventional Commit that names the source repository and the
commit imported.

This supersedes ADR 0023's naming of `git subtree add --squash`. What ADR 0023
actually decided is unchanged and remains in force: the import is squashed, the
188 commits are not grafted in, the import commit says where the history lives,
and the archived `nvim-config` repository must not be deleted because it is the
only place that history survives.

The `git-subtree-dir` and `git-subtree-split` trailers are what this gives up.
They exist so that `git subtree pull` and `git subtree push` can find the split
point later — a workflow ADR 0023 explicitly does not leave open, since after
the import there is nothing to pull from and the remote is archived. Nothing of
operational value is lost.

## Consequences

`git subtree` commands will not recognise `config/nvim` as a subtree. That is
the retired workflow, not a capability worth keeping; if it were ever needed,
`git subtree add --squash` against a fresh prefix would re-establish it.

The general lesson is worth stating because it will recur: **a porcelain
command that writes its own commit messages can conflict with a repository's
commit convention, and the plumbing equivalent is often the way through.** The
conflict is not visible until the command is run, so an ADR that names a
specific command is making a claim it has not tested. Naming the *outcome* and
leaving the mechanism to the implementation would have avoided needing this
ADR at all — worth remembering the next time an ADR reaches for a command name.
