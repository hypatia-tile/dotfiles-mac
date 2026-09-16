---
name: step-setup
description: Settle how a learning project runs its steps, and write that down as the repository's own step-start and step-review skills. Use when a repository with docs/roadmap.md has no step skills of its own, when the way it runs steps has settled and should be crystallised, or when the current way chafes and needs renegotiating. The user may phrase this in Japanese.
---

Carve a learning repository's own `step-start` and `step-review` out of a
conversation with the owner. The user-scope pair of the same names is
deprecated and goes away once nothing depends on it (dotfiles-mac #126).
**This skill decides nothing about how a project should work.** It removes the
setup friction around the conversation that decides it, and writes the outcome
where the agents will find it.

The operating detail of a learning project varies by repository and by what is
being learned, and the variation is not noise: who writes the code is inverted
in some repositories, the amend rule has exceptions, what counts as verified
differs. A user-scope skill that fixed those would be wrong somewhere. So this
one holds the shape of the answer and nothing of its substance.

## Before the conversation

Find out what already exists — not to prefill the answers, which are the
owner's, but to know what is being replaced.

1. `docs/roadmap.md` — the steps, and any working-contract section. If there is
   no roadmap, there is no plan yet: propose settling that with `grilling`
   first, and stop here.
2. `.claude/skills/` — a repository that already carries its own conventions
   skill has decisions in it that must not be lost.
3. `git status` — a dirty tree means something is mid-flight. Finish that first.

Say in one line what you found and what the conversation will replace.

## The conversation

Run it with the **`grilling`** skill, on the subject of how this repository runs
a step from start to close.

**Bring no question list.** Which axes matter is what the conversation is for,
and a checklist would reimpose the uniformity this skill exists to undo. Let
the owner's answers open the branches.

## What to write

Two skills, `<repo>/.claude/skills/step-start/` and
`<repo>/.claude/skills/step-review/`, each a `SKILL.md` that answers:

- **When it is invoked** — the frontmatter `description`, in the terms the
  owner actually uses, including Japanese phrasings if that is how they ask
- **What to read before starting** — the roadmap, the sources of truth for this
  project, whatever the owner named as required reading
- **What to produce** — the spec, or the findings: what it contains and what it
  never contains
- **Where the record goes** — issue, comment, discussion, roadmap checkbox, and
  in which order relative to the conversation
- **When it is done** — the condition that ends the step, and who declares it

Say nothing about the division of labour beyond what the owner decided. Do not
carry over "the AI never writes code": in some repositories the AI writes all
of it, and the code is the study material.

Also fold in the working contract itself — who does what, and **why**. It moves
out of `docs/roadmap.md` and into these skills, because the roadmap's readers
are mostly agents and a rule written twice is a rule that will disagree with
itself. The roadmap keeps the goal and the steps.

If the repository already has a conventions skill that covers running steps,
move those parts — with the reasoning and the incidents behind them, which are
the valuable half — into the two new skills, and delete them from the original.
One home per rule.

## Where it goes

```sh
mkdir -p .codex/skills
ln -s ../../.claude/skills/step-start  .codex/skills/step-start
ln -s ../../.claude/skills/step-review .codex/skills/step-review
```

The mirror is not optional if the owner uses Codex there: Codex reads a
repository's skills from `.codex/skills` and `.agents/skills`, never from
`.claude/skills` (measured on codex-cli 0.154.0). A relative symlink resolves
to the canonical file, and git stores it as a link rather than a second copy.

Then check the new paths are not swallowed: `git status --short` must show
them. A `.gitignore` that ignores `.claude/` leaves the skills working on this
machine and absent from every clone, with nothing to see.

## Write, then stop

**Never commit.** Who runs `git` is one of the things the conversation just
decided, and it differs — in one repository the agent commits and pushes, in
another every `git` write is the owner's. Report what was written, name the
roadmap section that was removed, and let the owner take it from there.

The skills are live the moment they are written: an agent in that repository
picks them up on its next session, before anything is committed. So do not stop
half-way — if the conversation is cut short, leave the repository as it was.
