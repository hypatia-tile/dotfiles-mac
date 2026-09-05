# Documentation index

This answers two questions: **where is X**, and **does it describe the system
as it is now**. Some documents here are records of the 2026-07 migration and
are knowingly out of date; they are marked as such below and in their own
opening lines.

## Changing something

Procedures live in skills, not in these documents (ADR 0019). Each is
`.claude/skills/<name>/SKILL.md` — Claude Code loads them automatically, other
agents can read the file directly.

| Skill | Use it when |
|---|---|
| `config-change` | Installing or removing a package, adding or editing a tool's configuration, a Homebrew entry, an environment variable, a macOS default. **The default entry point.** |
| `lock-review` | A weekly `chore(deps): update flake.lock` PR is open |
| `preflight` | Verifying a change against the CI gates before pushing |
| `ship-pr` | A committed branch needs to become a green, mergeable PR |
| `adr-new` | A decision needs recording |
| `ops-qa` | "How does X work here?" / "Why is it like this?" |
| `keybinding-doctor` | A key or chord is swallowed, produces the wrong character, or fires the wrong command |

Applying is always the owner's manual step, and nothing else in this
repository performs it:

```sh
sudo darwin-rebuild switch --flake .#Kazukis-MacBook-Air
```

Merged-but-not-switched is a normal intermediate state.

## Current documents

| Document | What it holds |
|---|---|
| [`../AGENTS.md`](../AGENTS.md) | Rules for coding agents — the source of truth for them |
| [`../CLAUDE.md`](../CLAUDE.md) | Claude Code specifics: the `settings.json` guardrails, how skills are tracked |
| [`operations.md`](operations.md) | Day-to-day semantics: Home Manager placement rules, Nix on this machine, CI behavior, known quirks |
| [`rollback.md`](rollback.md) | Recovery when a switch goes wrong |
| [`adr/`](adr/) | The decisions, 0001–0025, with their rationale |

## Pending input

Not historical — this is material for work that has not started.

| Document | Status |
|---|---|
| [`discovery/macos-defaults-snapshot.md`](discovery/macos-defaults-snapshot.md) | Input for the `system.defaults` adoption phase (ADR 0002), still unstarted. Values were read on 2026-07-13 and may have drifted; re-read before relying on them. |

## Historical records — the 2026-07 migration

These describe a completed project rather than the current system, and are
**not maintained**. They are kept in place because the ADRs reference them by
path and ADRs are immutable (ADR 0019).

| Document | What it was |
|---|---|
| [`requirements.md`](requirements.md) | The migration requirements R-01 to R-20, all satisfied |
| [`design/flake-design.md`](design/flake-design.md) | The design ADR 0014 adopted. Its §5 Homebrew block no longer matches `modules/darwin/homebrew.nix`, and its §3 note about converting git to `programs.git` was withdrawn by ADR 0020 |
| [`discovery/inventory.md`](discovery/inventory.md) | The 2026-07-13 scan of the machine and the legacy repositories, with the owner's per-row verdicts |
| [`discovery/keybindings-inventory.md`](discovery/keybindings-inventory.md) | The 2026-07-29 keybinding survey behind ADR 0017. Its four-layer table is still the reference for *where* a keybinding fix belongs |
| [`runbook.md`](runbook.md) | The cutover procedure, the post-cutover checklist, and the legacy-restore path |

## Deferred work

Not in this directory. Deferred work is filed as GitHub issues (ADR 0019):

```sh
gh issue list --state open
```
