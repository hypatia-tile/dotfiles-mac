# 0033. Tell every agent who owns the host environment

- Status: Accepted
- Date: 2026-10-01

## Context

The rules for changing this machine live in this repository, and an agent
reads them only when it works here. An agent working in any other repository
knows none of it. Two failures follow:

- **It changes the environment in place.** It edits `~/.zshrc` or a file
  under `~/.config`, runs `brew install` or `nix profile install`, or writes a
  macOS default. A projected payload is a read-only copy (ADR 0026), so the
  edit either fails or is overwritten on the next projection; an ad hoc
  install drifts from the declaration until a switch removes it.
- **It diagnoses from general knowledge.** Asked why a tool is missing from
  `PATH` or a key does not work, it answers from how Nix, Home Manager or
  Homebrew usually behave, not from how this host is layered.

The first is the one that does damage, and it happens at the moment the agent
does not think of itself as touching the environment at all.

**Nothing reaches such an agent today.** There is no user-scope instruction
file: neither `~/.claude/CLAUDE.md` nor `~/.codex/AGENTS.md` exists. The
user-scope skills (ADR 0028) are the only channel, and a skill is loaded only
when its description matches — which "inspecting the environment" rarely
announces.

**The projector is not macOS-only.** `bin/project.sh` is also run on NixOS
hosts for lightweight configuration, so everything declared in
`modules/payloads.tsv`, user-scope skills included, lands there too. On those
hosts this repository does not own the system: `hypatia-tile/nixos-config`
does, and Home Manager is installed globally without being declared in any
repository, so some `$HOME` symlinks — Neovim's among them — are owned by
nothing written down. "This repository is the source of truth for the
machine" is true on the Mac and false on NixOS.

**This repository is public.** A record that names the repository an agent was
working in can name a private one.

## Decision

**A user-scope skill, `host-environment`, carries the substance.** It lives in
`config/agents/skills/host-environment/` and is linked into both agents like
every user-scope skill (ADR 0028). It holds only what does not drift:

- the boundary — everything outside the current repository's working tree is
  in scope; the repository's own devShell, lockfiles and local config are not,
  and a missing tool is reached repository-locally first;
- what is never done from another repository — edits outside the working tree,
  global installs, `defaults write`, `sudo`, rebuilds, projection;
- how ownership is decided — per path or per tool, by observation, against a
  table of where the resolved path lands. The owner repositories are located
  on the spot, never from a fixed path. An ambiguous or unknown result stops
  the agent and goes to the owner;
- that a diagnosis reads the owner's own documents.

What the layering is in detail — which paths are projected, which layer a
change belongs in — is not restated; the skill sends the agent to
`modules/payloads.tsv`, `AGENTS.md` and `docs/README.md`.

**A user-scope instruction file points at it.** `config/agents/instructions.md`
is a few lines naming the boundary and the skill, placed as
`~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`. It is loaded in every session,
which is what makes up for a skill's uncertain triggering. It is not named
`AGENTS.md` in the repository, where Codex would read it as a nested
instruction file for `config/agents/`. It carries this concern only; whether
other rules belong in it is a separate decision.

**The instruction file is a `copy`, not a `link`.** It is the entry point to a
safeguard, and a safeguard the guarded agent can rewrite is not one. A change
to it therefore goes live when the projector runs, not when the file is saved.
The skill stays a `link`, as ADR 0028 decided for every skill.

**A needed change becomes an issue in the owner repository, filed only on the
owner's approval.** The agent drafts it, checks the draft for secrets
(gitleaks, run through `nix run` because it is installed only in this
repository's devShell, plus a read for what gitleaks misses), and shows the
owner the draft, the result and a choice: name the originating repository or
leave it out — offered every time, public or private. That approval is where
the owner decides whether to trust the originating repository and the
proposal; there is no second check at triage. Issues filed this way carry the
`from-agent` label, which exists to find them, not to mark them as untrusted.

## Consequences

- An agent in any repository on any host that runs the projector is told the
  boundary at session start, and has a procedure for the case it would
  otherwise improvise.
- `~/.claude/CLAUDE.md` is read-only, so Claude Code's own ways of writing
  user memory into it (`/memory` on the user file, `#` notes) fail. They are
  not in use; using them later means changing this decision.
- Codex reading `~/.codex/AGENTS.md` as its global instructions is the
  documented behaviour, not one measured here; it is verified at the
  post-switch check, in a fresh Codex session, together with the skill.
- The ownership table is reliable on the Mac and deliberately incomplete on
  NixOS, where it answers "ambiguous" more often than not. Settling NixOS
  ownership is deferred to an issue.
- Nothing mechanical stops an agent that ignores both the instruction and the
  skill. A global pre-tool-use hook that refuses writes under `$HOME` and
  global installs would; it is deferred to an issue as a separate concern.
- Running the skill is not recorded anywhere; only the issues it produces are.
