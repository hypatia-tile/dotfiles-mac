---
name: conversation-language
description: Keep English terminology and procedure vocabulary when the conversation is Japanese — do not force-translate agent-native terms. Use whenever the owner is writing in Japanese (grilling, design talk, everyday ops), including when other skills are also in play.
---

# Conversation stays bilingual on purpose

When the owner writes in Japanese, reply in Japanese for framing and
explanation. Do **not** translate the terms an English-native agent already
uses cleanly — forced Japanese for those makes the exchange harder to follow,
not easier.

This skill is about the **conversation**. GitHub artifacts (issues, PRs,
commits, review comments) follow `github-language` instead, even in a Japanese
session.

## When it applies

Only while the owner is writing in Japanese. An English session needs nothing
from this skill.

## What stays English

Leave these in English (ASCII / their usual spelling), even inside a Japanese
sentence:

- **Terminology** — tool and file names, attributes, ADR numbers, skill names
  (`flake.lock`, `preflight`, `lazy-lock.json`, `conversation-language`, …).
- **Procedure vocabulary** — the verbs and nouns the agent normally uses for
  git and apply steps: `commit`, `push`, `merge`, `rebase`, `switch`,
  `checkout`, Conventional Commit types (`feat`, `fix`, `chore`, …), and
  the names of skills being invoked.

Japanese is fine for connective prose, questions, and recommendations around
those terms.

## What this is not

- Not a reason to write repository files or GitHub text in Japanese — that is
  still `github-language` / the repository's own rules.
- Not a glossary. If a term is already clear in English, do not invent a
  Japanese stand-in.
