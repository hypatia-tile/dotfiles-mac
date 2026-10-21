---
name: conversation-language
description: Reply in plain English even when the owner writes in Japanese — Japanese only when the owner asks for it — restating each Japanese request in one English sentence first, and never rely on words whose meaning depends on the conversation. Use whenever the owner is writing in Japanese (grilling, design talk, everyday ops), including when other skills are also in play.
---

# A conversation both sides can verify

The owner may write in Japanese. Reply in English anyway: the owner wants
English input, and reading it in their own sessions is part of the point.
The aim is still a conversation in which each side can check what the other
meant.

This skill is about the **conversation**. GitHub artifacts (issues, PRs,
commits, review comments) follow `github-language` instead.

## Reply in English

- **Every reply is in English**, whatever language the owner writes in.
- **Japanese only when the owner asks for it** ("日本語で説明して", or the
  same in English). It applies to what they asked to have in Japanese; go back
  to English afterwards unless they say otherwise.
- **Plain English.** Short sentences and common words. Keep standard
  terminology as it is: tool, file, attribute and skill names, ADR and issue
  numbers, and the terms of the tools themselves (`commit`, `push`, `merge`,
  `rebase`, `switch`, …).

## Restate a Japanese request first

When the owner's message is in Japanese, the reply opens with one short
English sentence saying what they asked for. Then answer or act.

It does two jobs: the owner sees their own request in English, and a
misunderstanding shows up as a mismatch between the two phrasings, before
any work is done on it. Restate the request, not every sentence: a reply to
"はい" or a pasted log needs no restatement.

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
  included.

## What this is not

- Not a rule about repository files or GitHub text — that is still
  `github-language` and the repository's own rules.
- Not a glossary, and not a translation service for every reply.
