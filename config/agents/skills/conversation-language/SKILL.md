---
name: conversation-language
description: Keep standard terminology in English when the conversation is Japanese, translate everything else, and never rely on words whose meaning depends on the conversation — confirm unclear ones and rephrase into standard terms. Use whenever the owner is writing in Japanese (grilling, design talk, everyday ops), including when other skills are also in play.
---

# A conversation both sides can verify

When the owner writes in Japanese, reply in Japanese. Keep a word in English
only when it is standard terminology. The aim is a conversation in which each
side can check what the other meant.

This skill is about the **conversation**. GitHub artifacts (issues, PRs,
commits, review comments) follow `github-language` instead, even in a Japanese
session.

## When it applies

Only while the owner is writing in Japanese. An English session needs nothing
from this skill.

## What stays English

**Standard terminology**: words with a fixed meaning in their field, that
the owner would find in that tool's documentation or the field's usual
vocabulary.

- Tool, file, attribute and skill names, ADR and issue numbers
  (`flake.lock`, `preflight`, `lazy-lock.json`, `conversation-language`, …).
- The terms of the tools themselves: `commit`, `push`, `merge`, `rebase`,
  `switch`, `checkout`, Conventional Commit types (`feat`, `fix`, `chore`, …).

**Not every English word is terminology.** An ordinary word left in English
inside a Japanese sentence makes the reply harder to follow, not easier.
Translate it.

## No words whose meaning depends on the conversation

A word that means something only because this conversation, an issue or a
plan gave it that meaning confuses in both languages. That includes labels
the agent coins ("signal", "stage" used as a name) and words the owner coins.

- **Describe the thing concretely** instead of naming it. If a name is
  needed, define it in standard terms the first time it appears.
- **Before sending, scan the reply** for words a reader outside this
  conversation would not understand.

## Confirm and rephrase

- **When unsure whether a word the owner uses is project-local or standard
  terminology, ask.** Do not guess, and do not leave it vague.
- **Rephrase into standard terminology actively**, the owner's words
  included. A misunderstanding then shows up as a mismatch between the two
  phrasings, early, instead of later as wrong work.

## What this is not

- Not a reason to write repository files or GitHub text in Japanese — that is
  still `github-language` / the repository's own rules.
- Not a glossary. If a term is already clear in English, do not invent a
  Japanese stand-in.
