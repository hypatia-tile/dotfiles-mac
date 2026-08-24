# 0019. Steady-state documentation and skill layout

- Status: Accepted
- Date: 2026-08-24

Promoted to Accepted by shinokun, 2026-08-24.

## Context

ADR 0018 finalized the migration on 2026-08-16. The repository has been the
single source of truth since the 2026-07-14 cutover, but its documentation
still describes a *project* rather than a *system*, and its skills still
cover every kind of change except the most common one.

A survey on 2026-08-21 found the following.

**Documents that no longer describe reality.**

- `README.md` states "Migration in preparation. No flake exists here yet" and
  that the ADRs are "all currently `Proposed`". Both are false.
- `docs/design/flake-design.md` §5 shows a Homebrew module that contradicts
  `modules/darwin/homebrew.nix`: it passes `with-native-comp` and
  `with-poll`, which do not exist on `emacs-plus@30` and abort the install
  (fixed in #22), and omits `imagemagick` (#24), `tailscale-app` (#33) and
  the tap `trusted` flag (#21). Its §6 implementation phases are all merged.
- `docs/requirements.md` R-01 through R-20 are all satisfied.
- `docs/runbook.md` §4 lists archiving the legacy repositories as an unstarted
  owner step; both `hypatia-tile/dotfiles` and `hypatia-tile/nix-darwin` are
  in fact archived.
- `docs/runbook.md` mixes a historical cutover procedure (§2, §4) with a live
  safety procedure (§3 rollback).

**Procedures duplicated between documents and skills.**

- The Neovim change loop is written both in `docs/operations.md` §1 and in
  `.claude/skills/nvim-bump/SKILL.md`. PR #37 exists solely to re-synchronize
  the two — the duplication has already cost a commit.
- The markdownlint MD060 caveat is written three times: `AGENTS.md`, the
  `migration-check` skill, and `docs/operations.md` §4.
- Three of the four sections of `AGENTS.md` restate skill content
  (running the CI gates locally, MD060, verifying runtime state empirically).
- `CLAUDE.md` is loaded into every session and carries two indexes — a skill
  list and a `docs/` layout — that duplicate the skill frontmatter the
  harness already surfaces and the documents themselves.

**A missing procedure and an uncaptured obligation.**

- Adding or removing a package, or adding a configuration file, is the most
  frequent change in the repository and has no captured procedure, while
  every less frequent one does (`adr-new`, `nvim-bump`, `keybinding-doctor`,
  `ship-pr`, `migration-check`). It is re-derived from the ADRs each time.
- ADR 0018 enabled the weekly `update-flake-lock` workflow. Reviewing its PRs
  is now the most frequent recurring obligation here, and the procedure — the
  inverted closure-diff criterion, rebase rather than squash, the post-switch
  check of the tools that moved — exists only in the body of PR #41, outside
  the repository.
- ADR 0018 recorded that `migration-check`'s name had become a misnomer and
  left the rename as a later cleanup.

**Deferred work has no home.** `docs/operations.md` §5 mixes permanent
knowledge (Homebrew tap trust, the cosmetic "Uninstalled N" count, optional
dependencies of `emacs-plus@30`) with transient TODOs (the `system.defaults`
phase, the `HISTFILE` fix, moving `zsh-abbr` off Homebrew). GitHub Issues is
unused: zero issues across 42 pull requests.

## Decision

**Skills are the source of truth for procedures; documents index them.** Where
a procedure currently exists in both, the document keeps only the decision and
the sharp edges and points at the skill. This applies retroactively to the
Neovim loop in `docs/operations.md` §1.

**Rename `migration-check` to `preflight`**, discharging the cleanup ADR 0018
deferred. Only live references are updated; ADRs 0009, 0013, 0014, 0016 and
0018 keep the historical name, which is what the skill was called when those
decisions were made.

**Add `config-change`**, the single entry point for everyday changes. It owns
three things and nothing else:

- the layer-decision table — nixpkgs or Homebrew (ADR 0005), darwin or Home
  Manager (ADR 0006), plain files or `programs.*` (ADR 0020);
- the edit itself;
- the post-switch check appropriate to the kind of change.

It delegates verification to `preflight`, pull requests to `ship-pr`, and
Neovim to `nvim-bump`, and must not restate their steps. Before starting it
consults `gh issue list` for related deferred work.

**Add `lock-review`** for the weekly `flake.lock` pull requests, promoting the
body of PR #41 into a procedure: the closure-diff criterion is inverted
(version changes are the expected outcome, not a red flag), merging is rebase
rather than squash so the dedicated lock commit survives (ADR 0011), and the
post-switch check names the tools whose versions moved.

**`AGENTS.md` becomes the tool-agnostic source of truth for agent rules.**
`CLAUDE.md` keeps only Claude-specific matter and points at it; a future
`GEMINI.md` does the same. Adding an agent must not fork the rules. The three
sections of `AGENTS.md` that restate skills are deleted.

**`CLAUDE.md` carries rules only.** Its skill list and `docs/` layout move to
a new `docs/README.md`, which is the single index and classifies every
document as current or historical.

**Documents are not moved.** ADR 0014 delegates its own content to
`docs/design/flake-design.md`, and ADRs 0002, 0003, 0015, 0017 and 0018 name
`docs/discovery/` and `docs/runbook.md` by path; those references must keep
resolving, and the ADRs are immutable. Instead, every document that is not a
description of the current system opens with a status line saying so.

**Split the live rollback out of `docs/runbook.md` into `docs/rollback.md`**,
covering generation rollback only, so the procedure needed under pressure is
one short self-contained file. `runbook.md` becomes wholly historical. The
legacy-restore layer stays there, and `rollback.md` references it in a single
line with its true cost: it restores the pre-cutover state of July 2026 and
discards everything merged since, so it is a return to the abandoned regime
rather than a rollback of a recent change.

**Deferred work moves to GitHub Issues.** `docs/operations.md` §5 keeps only
knowledge that does not expire. Because issues are invisible to an agent's
context, `config-change` checks them before starting and `ops-qa` adds them to
its search order.

## Consequences

- A procedure exists in exactly one place, so re-synchronization commits like
  PR #37 stop being necessary. The cost is indirection: reading a document no
  longer tells you the steps, only where they live.
- `CLAUDE.md` stops churning. Because it is injected into every session,
  keeping indexes out of it means routine additions no longer perturb the
  always-loaded context.
- Adding an agent (Codex, Gemini CLI) costs a pointer file rather than a
  third copy of the rules.
- The everyday change acquires a type. The trade-off is that `config-change`
  can drift from the ADRs it summarizes; its decision table is a summary of
  ADRs 0005, 0006 and 0020 and has no independent authority.
- Deferred work becomes visible in a tracker but invisible in `grep`. This is
  accepted on the condition that the two skills above bridge it back; if that
  bridge fails in practice, the deferred list returns to the repository.
- The historical documents keep their paths and therefore their ADR
  references, at the cost of `docs/` still listing them. `docs/README.md` is
  what makes the distinction legible.
- `docs/runbook.md` §2 and §4 are frozen as a record of the 2026-07 cutover
  and stop being maintained.
