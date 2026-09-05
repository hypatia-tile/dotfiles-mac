# 0023. Squash the Neovim subtree import

- Status: Accepted
- Date: 2026-09-05

Promoted to Accepted by shinokun, 2026-09-05.

## Context

ADR 0021 decided to bring `nvim-config` into this repository as a `git
subtree`, so that the working-tree symlink rule can apply to Neovim. It stated
that the import would preserve the imported repository's history, "since the
remote is being retired".

That reasoning does not survive contact with the other half of the same
decision. ADR 0021 also archives `nvim-config` rather than deleting it,
following ADR 0010 and ADR 0018 — so the remote is retired but not gone, and
its 188 commits remain reachable there indefinitely.

What preserving them here would cost is the readability of this repository's
own history. Grafting 188 commits of another project's development into
`git log` is permanent and affects every future reader, in exchange for
convenience that a link already provides.

This ADR exists rather than an edit to 0021 because ADRs are not edited once
accepted; a changed decision gets a new one (ADR 0007, ADR 0019).

## Decision

Import the subtree with `git subtree add --squash`, as a single commit.

The import commit names `hypatia-tile/nvim-config` and states that the full
history lives there, so a reader who wants it knows where to look. Retiring
that repository stays an *archive*, never a deletion — after a squashed import
it is the only place the history survives, which makes ADR 0021's archiving
clause load-bearing rather than merely tidy.

This supersedes the clause of ADR 0021 that the subtree import preserves
`nvim-config`'s history. Everything else in ADR 0021 stands: the subtree
itself, its destination at `config/nvim`, the removal of the flake input, and
the archiving.

## Consequences

`git log` in this repository continues to describe this repository. The cost is
one level of indirection for anyone tracing a line of Neovim configuration back
to its origin: `git log` here stops at the import commit, and the trail
continues in the archived repository.

The archived `nvim-config` repository becomes load-bearing. Deleting it later
would destroy history that exists nowhere else, so it must not be treated as
disposable — a stronger obligation than the one ADR 0010 and ADR 0018 attached
to the legacy repositories, whose contents were migrated in full.

`git subtree pull` from the retired remote is not a workflow this leaves open,
which is correct: after the import there is nothing to pull from.
