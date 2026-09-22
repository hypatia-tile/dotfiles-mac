---
name: github-language
description: Write GitHub artifacts in the language of the repository they belong to — English by default, Japanese where the repository's README is Japanese. Use BEFORE writing or editing any GitHub issue, pull request, review comment, or commit message — always applies, even when the conversation is in Japanese.
---

# GitHub artifacts follow the repository's language

Text published to GitHub is written for the repository's readers, not for the
person in this conversation. The conversation language never decides it: a
Japanese session on an English repository still writes English.

## Which language

The top-level `README` is the signal. Read it before writing:

- **English README, or no README at all** — write English. This is the
  default, and it is what an unfamiliar repository gets.
- **Japanese README** — Japanese is allowed. Match what the repository's
  existing issues and pull requests already use; where they are mixed or
  absent, follow the conversation language.
- **Bilingual README** — judge by the main prose, and write English when it
  is genuinely both.

An explicit instruction in the repository outranks the README: `AGENTS.md`,
`CONTRIBUTING.md`, or an issue or PR template that names a language decides
it. `dotfiles-mac`, for instance, requires English for every artifact.

## What this covers

Issue titles and bodies, pull request titles, bodies and review comments, and
commit messages. Conventional Commit prefixes (`feat(skills):`) are ASCII
keywords in any language — only the subject and body follow the repository.

Files in the repository follow the file, not this rule: a Japanese document
stays Japanese, an English one stays English.

## Existing artifacts

When editing an artifact written in the wrong language, translate it rather
than appending a second language alongside it. Leave artifacts that are
already in the repository's language alone — this rule is not a reason to go
back and retranslate what is there.
