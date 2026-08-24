# GEMINI.md

The rules for working in this repository are in **`AGENTS.md`**, which is
tool-agnostic and is the source of truth for them (ADR 0019). Read it first
and follow it; this file exists only so that Gemini CLI finds the rules, and
adds nothing of its own.

`docs/README.md` is the index of every document and skill.

Two rules matter most and are easy to violate by habit:

- **Never run `darwin-rebuild switch`, any activation script, or `sudo`.**
  Applying a change is the owner's manual step; your work is build-only.
- **Never commit or push automatically.** Prepare the change and a proposed
  Conventional Commit message, and stop there.

Procedures are written as skill files under `.claude/skills/<name>/SKILL.md`.
They are not Gemini-specific — read the relevant file directly. The everyday
entry point is `config-change`, and `preflight` is the verification gate to
run before proposing a pull request.
