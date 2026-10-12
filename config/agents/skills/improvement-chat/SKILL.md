---
name: improvement-chat
description: Open a casual conversation about the current repository's design and operation, surface what could be improved, and — once the owner agrees on one candidate — hand it to grilling. Use when the owner wants to chat, look back, or find something worth improving without a concrete task yet. The owner may phrase this in Japanese ("雑談しよう", "改善点を探したい", "何か気になるところある?").
---

# Improvement chat

A conversation first, a plan second. The owner has no task yet; the point is
to find one worth doing, and the finding happens in the talk, not in a report
the agent prepares beforehand.

The subject is **the repository this session is in** — its design, its
workflow, the friction of operating it. Not the owner's life in general, and
not other repositories.

## Before the conversation

Gather enough to have something to talk about, and say nothing about it yet:

- the repository's own entry points — `AGENTS.md`, `CLAUDE.md`, `README.md`,
  and whatever index they point to;
- `git log --oneline -30`, for what has been moving and what keeps being
  fixed;
- `gh issue list --state open`, for what is already known and deferred.

Then open with a question, not a list of findings.

## The chat

- **One thread at a time, short turns.** Ask what has been annoying, what took
  longer than expected, what the owner keeps working around. Follow their
  answer rather than a prepared agenda.
- **Bring observations, grounded.** When something you read is relevant, say
  what you saw and where — the file, the commit, the issue. Keep what you
  checked apart from what you infer, and look up a fact before raising it
  rather than asking the owner for it.
- **Do not solve yet.** No edits, no branches, no ten-point improvement plans.
  A fix proposed mid-chat ends the exploration early.
- **Check what is already recorded.** If a candidate is an open issue, say so
  and read it; the reason it was deferred is usually written down there.

## Handing over to grilling

A candidate is worth naming when the owner reacts to it, when the same
friction shows up more than once, or when the documents and the repository
disagree.

Name it in two or three sentences: what it is, why it matters, and what is
already known. Then ask whether to work it through. **Only on an explicit
yes**, run the **`grilling`** skill on that one candidate. On anything else,
go back to the chat, or end it if the owner is done.

One candidate per grilling. Others that came up are listed at the end, not
grilled in the same pass.

## After grilling

Summarise the shared understanding, then propose where it should be recorded —
an issue, a decision record, a skill — following the repository's own rules
for that. **Propose, do not do it**: creating the record, editing, branching
and committing are separate steps the owner asks for.

Nothing in this skill writes to the repository.
