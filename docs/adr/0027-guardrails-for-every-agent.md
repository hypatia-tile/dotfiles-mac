# 0027. Enforce the agent guardrails for every agent, not only Claude Code

- Status: Proposed
- Date: 2026-09-14

## Context

`AGENTS.md` states the hard rules for "any coding agent working in this
repository", and ADR 0019 made it the tool-agnostic source of truth so that
adding an agent "costs a pointer file rather than a third copy of the rules".
The rules did not fork. Their **enforcement** did, and nothing recorded it.

ADR 0013 decided that `.claude/settings.json` "enforces the safety boundary
mechanically", and listed as a consequence that "guardrails persist across
sessions and future tooling". ADR 0008 names the same file as the thing that
implements "never push, commit only on instruction". ADR 0018 retained those
guardrails in words whose subject is Claude — "Claude never runs
`darwin-rebuild switch`, any activation script, or `sudo`" — and ADR 0022 left
the deny rules "exactly as they are". Each was accurate when written, because
Claude Code was the only agent working here.

That is no longer the case. `codex` and `cursor-agent` are declared in
`modules/home/packages.nix`, and Codex has already written into this
repository: `~/.codex/rules/default.rules` holds an always-allow rule for
`cp /private/tmp/java.lua ../dotfiles-mac/config/nvim/ftplugin/java.lua`,
dated 2026-09-12. A Codex or Cursor session here is bound by `AGENTS.md` only
as far as the model reads and follows it. `.claude/settings.json` does not
apply to either, so nothing mechanical stops them from running
`darwin-rebuild switch`, `git push`, `nix flake update`, or `sudo`.

The Claude deny list is also narrower than the rules it implements:

| `AGENTS.md` hard rule | `.claude/settings.json` today |
|---|---|
| never `darwin-rebuild switch` | denied, with `activate` and `sudo darwin-rebuild` |
| never **any** activation script | only the `darwin-rebuild` forms |
| never **`sudo`** | only `sudo darwin-rebuild` |
| never push; commit only on instruction | `git push` denied; `git commit` asks |
| `flake.lock` moves only in dedicated commits | `nix flake update` denied |
| legacy repositories are read-only; never run their `bin/dot-link.sh` | `Edit`/`Write` denied; shell writes and `dot-link.sh` are not |

`CLAUDE.md` already concedes the last row: shell-level writes "cannot be fully
pattern-blocked". A static permission list matches command prefixes; it cannot
see `… && sudo …` or a redirection into a legacy path.

What the three agents support was established from the binaries of the pinned
versions — Claude Code 2.1.266, Codex 0.154.0, cursor-agent 2026.08.31:

- **All three run a pre-tool-use hook** that receives the tool call as JSON on
  stdin and can refuse it. Codex's `PreToolUse` input carries `tool_name` and
  `tool_input` and accepts `hookSpecificOutput.permissionDecision` — the same
  shape as Claude's. cursor-agent translates a Claude-style
  `permissionDecision` on `PreToolUse` into its own `permission`.
- **Project-scoped hook configuration exists for all three.** Codex reports
  "Error parsing project hooks config file", and requires a hook to be trusted
  (`trusted_hash`) before it runs. cursor-agent loads project hooks and, beside
  them, `claudeUserHooks`, `claudeProjectHooks` and `claudeProjectLocalHooks` —
  it reads Claude's hook configuration as well as its own.
- **A crashing hook does not block in Claude or Codex.** They refuse a call
  only when the hook explicitly says so. cursor-agent has a per-hook
  `failClosed` flag that blocks on a crash or timeout.
- **Static lists differ per agent**: `permissions` in Claude's settings,
  `prefix_rule(…)` in Codex's `.rules` files, `Shell(…)` entries in
  cursor-agent's `.cursor/cli.json`. Keeping three of them identical is the
  kind of silent drift #112 documents for `preflight` against CI.

## Decision

**The guardrails are enforced for every agent that works in this repository,
by one shared hook.** `bin/agent-guard.sh` reads the pre-tool-use JSON, decides,
and answers. It is registered as a project-scoped `PreToolUse` hook in two
places: `.claude/settings.json`, which serves Claude Code and cursor-agent, and
`.codex/hooks.json`, which serves Codex. The deny list lives in that script and
nowhere else.

**The answer has exactly one shape.** Allowing prints nothing — answering
"allow" would skip the agent's own permission prompt. Denying or asking prints
`{"hookSpecificOutput": {"hookEventName", "permissionDecision",
"permissionDecisionReason"}}` and no other key. Codex validates the answer
with `additionalProperties: false`: an earlier draft added cursor-agent's
native `permission` and `user_message` beside it, Codex rejected the whole
object as invalid, and **ran the denied command**. cursor-agent reads the
Claude form without them. The implementation's test suite fails any answer
with an extra key.

**What it enforces** is the hard rules of `AGENTS.md`, not only today's Claude
list:

- deny `darwin-rebuild switch` and `activate`, in any position of a compound
  command;
- deny **any** `sudo`. Privileged steps are handed to the owner for a real
  terminal, which is also the only place `sudo` can prompt for its password;
- deny `git push` and `nix flake update`;
- deny running either legacy repository's `bin/dot-link.sh`, and shell
  commands that write into `~/github/dotfiles` or `~/github/nix-darwin`
  (`rm`, `mv`, `cp`, `ln`, `tee`, output redirection) — best effort, since a
  shell string is not fully decidable, but strictly more than a prefix list;
- deny file-writing tool calls whose path is inside either legacy repository;
- `git commit` asks. An agent whose hook protocol has no "ask" is **not**
  denied instead: that would block the commits the owner does instruct, and
  the agent's own approval flow still applies.

Secrets are out of scope. gitleaks already covers them in CI and in
`preflight`, and a hook-time heuristic would stop work on false positives.

**What it decides from** is the presence of a `command` or a file path in
`tool_input`, not `tool_name`. The agents name their shell and edit tools
differently, and the guard must not silently skip a tool it does not recognise
by name.

**How it fails:**

- A call with neither a command nor a path is outside the guard's remit and is
  allowed. Reads, searches and plans are not what these rules govern.
- A call that carries a command or a path the guard cannot parse is
  **denied**, with a reason naming `agent-guard`. An agent update that changes
  the input shape then stops the guarded operations loudly, instead of
  disabling the guard in silence.
- The script traps its own errors and emits a denial, because Claude and Codex
  treat a crashing hook as non-blocking. For cursor-agent that trap is also
  the only fail-closed layer: the Claude-format registration it reads cannot
  carry `failClosed`. What stays non-blocking in all three is a hook that
  cannot be started at all or exceeds its timeout.

**`.claude/settings.json` keeps its permission lists unchanged**, as a second
layer for Claude Code. ADR 0022's statement that those rules "stay exactly as
they are" remains true.

**cursor-agent is guarded through the Claude registration alone**, with no
`.cursor/hooks.json`. Measured: with both present, cursor-agent ran each hook
for every call — the guard twice. With only the Claude registration it ran the
guard exactly once per call and honoured its denials and its "ask". Giving up
`failClosed` is the price, and the script's own error trap covers the part of
it that matters (above).

**Codex has no "ask".** It reports "PreToolUse hook returned unsupported
permissionDecision:ask", so for Codex a call that would ask is allowed and left
to Codex's own approval flow, as decided above. The guard tells Codex apart by
its input: `turn_id` without `cursor_version`.

**Codex's registration names the checkout by absolute path.** Claude Code
expands `$CLAUDE_PROJECT_DIR` in a hook command; Codex offers no equivalent,
so `.codex/hooks.json` uses the same checkout path as `modules/common.nix`. A
Codex session in a worktree therefore runs the main checkout's guard, not the
branch's.

**Verified before it is relied on.** In a new session of each agent, a
harmless command the guard denies (`git push --dry-run`) must be refused, and
the implementation records the input JSON each agent actually sent. An agent
where the denial does not take effect is reported as a failure of this
decision, not worked around.

Measured on 2026-09-14 with the real guard behind a recorder, each agent asked
to run five steps in a scratch repository:

| Step | Claude Code | Codex | cursor-agent |
|---|---|---|---|
| `touch M && git push --dry-run` | denied, not run | denied, not run | denied, not run |
| `touch M && sudo -n true` | denied, not run | denied, not run | denied, not run |
| write a file containing `it's fine` | allowed (`Write`, `file_path` + `content`) | allowed (`apply_patch`, patch text in `command`) | allowed (`Write`, `file_path` + `content`) |
| `echo "never run sudo" > M` | allowed | allowed | allowed |
| `git commit --allow-empty -m probe` | asked; headless, so refused and not committed | allowed; Codex did not commit | asked; committed after approval |

Shapes that shaped the implementation: Claude and Codex both name the shell
tool `Bash` and send `tool_input.command`; cursor-agent names it `Shell`,
sends `cwd` as an empty string and the workspace in `workspace_roots`; Codex's
`apply_patch` puts the patch in `command`, which the guard must read as a patch
and not as shell. Claude Code ran headless (`claude -p`), where an "ask" has no
one to answer it and is reported as a refusal.

This supersedes **ADR 0013's clause that `.claude/settings.json` enforces the
safety boundary**, as the sole enforcement. The rest of ADR 0013 — its
repository skills, and CLAUDE.md restating the rules — is unaffected. It
widens the subject of the guardrails ADR 0018 retained from "Claude" to every
agent, without changing what they are, and ADR 0008's rule that agents commit
only on instruction and never push is unchanged in substance, enforced now by
the hook as well as the settings file.

## Consequences

- An agent added later is guarded by registering one script in its hook
  configuration, rather than by translating a deny list into a fourth format.
  The cost of adding an agent stays the pointer file ADR 0019 promised, plus
  one registration.
- The guard is code, and code has bugs that a declarative list does not. A
  false denial stops legitimate work in every agent at once; a missed pattern
  lets a command through in every agent at once. The fail-closed choice makes
  the first kind the likelier, and it is the kind that announces itself.
- Codex refuses to run an untrusted hook, so trusting `.codex/hooks.json` is a
  one-time manual step for the owner, and any change to that file needs trust
  again.
- The guard defends against an agent's mistakes, not against an agent that
  edits `bin/agent-guard.sh` or the hook registrations to get past it. Those
  edits are ordinary changes to this repository and are reviewed as such.
- Shell parsing stays best effort. The legacy-repository write check narrows
  the gap `CLAUDE.md` describes; it does not close it, and `CLAUDE.md` should go
  on saying so.
- The rules gain a third place where they are stated — `AGENTS.md` in prose,
  `.claude/settings.json` as a list, `bin/agent-guard.sh` as code. Only the
  last is authoritative for enforcement; the settings list is a subset kept as
  defence in depth, and `AGENTS.md` remains the source of truth for what the
  rules _are_.
