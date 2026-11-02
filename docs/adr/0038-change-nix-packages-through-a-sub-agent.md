# 0038. Change nix-packages from here only through a sub-agent

- Status: Proposed
- Date: 2026-11-03

## Context

Since ADR 0037, what is installed is declared in hypatia-tile/nix-packages,
and a tool that needs both repositories is added there first. `config-change`
said that change is made from a session in that checkout, never from one
here. In practice the package half is often wanted from a session here: on
2026-10-31 hypatia-tile/nix-packages#13 was fixed from one by hand, by reading
its `AGENTS.md`, running its `bin/hooks-health.sh`, committing through its
hooks and running its `bin/preflight.sh` (hypatia-tile/nix-packages#14). Those
steps were held only in that session's memory. #329 records the problem and
what the owner agreed on 2026-11-02.

What a session here lacks in nix-packages is smaller than it looks:

- the two `bin/agent-guard.sh` copies differ only in comments and in this
  repository's rule for the legacy repositories, so this repository's guard
  already enforces nix-packages' rules in a session here;
- nix-packages' `AGENTS.md` is not loaded, and neither are its skills. The
  only one, `lock-review`, is not part of adding or removing a package.

Nothing mechanical keeps a session here out of the nix-packages checkout:
the guard checks paths only against the legacy repositories.

## Decision

- **From a session here, nix-packages is changed only through the
  `nix-packages` sub-agent,** defined in `.claude/agents/nix-packages.md`. The
  main session never edits that checkout. A session opened in the checkout,
  under its own `AGENTS.md`, stays the other way.
- **The sub-agent's scope is the package half of `config-change`:** adding
  or removing a Nix package, a Homebrew cask or brew, or a font.
- **It runs inside the session that starts it.** This repository's settings,
  guard and permission prompts apply to it. It reads nix-packages'
  `AGENTS.md` first, and its tools are `Bash`, `Read`, `Edit` and `Write`, on
  the parent's model: no sub-agents of its own, no MCP tools and no `gh`.
- **It works in the main checkout.** It stops if the tree is not clean,
  branches from a freshly fetched `origin/main`, and leaves the checkout on
  the branch, where `bin/nix-packages-diff.sh` finds it by default.
- **It stops at the commit.** It reports the branch, each commit, the
  `bin/preflight.sh` result and a draft PR body, and pushes nothing. The
  parent session builds this host against the branch, hands the push to the
  owner, and opens the PR after it.
- **The guard is to enforce it,** by refusing writes into the nix-packages
  checkout from anything but this sub-agent, if Claude Code's `PreToolUse`
  input says which sub-agent made a call. That is verified before it is
  built, as #329's second stage. If it cannot be, the rule stays written only.

## Consequences

- The steps of a change in nix-packages are written down once, in the
  definition, instead of carried by memory from one session to the next.
- The owner still sees every permission prompt, and pushing and merging stay
  the owner's in both repositories (ADR 0036).
- The nix-packages checkout stays on a feature branch until the owner moves
  it back. Meanwhile `vulns host` reads that branch's `.vulns-defer`, which
  matters only for a change that edits it.
- The sub-agent is specific to Claude Code. A Codex session here has no
  equivalent, so it changes nix-packages from a session in that checkout.
  Once the guard enforces the rule, a Codex session here is refused such
  writes.
- A sub-agent's report is the parent's only view of its commits, so the
  parent must pass them on; a commit missing from the parent's report is
  still a reporting error (ADR 0036).
