---
name: step-start
description: Start the next step of a hand-written learning project. Identifies the first unchecked step in docs/roadmap.md, files it as a GitHub issue, and presents the spec. Use when the user asks to begin, resume, or move on to the next step; the user may phrase this in Japanese.
---

Run one step of a learning project. **This skill never writes code.** It produces a specification, the reasoning behind it, and verification steps. The user implements everything.

## Before starting

1. Read `docs/roadmap.md`. If it does not exist, the project has no agreed plan yet — propose settling the design with `grilling` first, and stop here.
2. Read the roadmap's working-contract section — its heading differs between repositories — and **follow that repository's own contract**. Who writes code, who runs commands, and which directories the AI may write vary per repository.
3. Run `gh issue list --state open`. If the previous step's issue is still open, **do not start a new step** — push for review and closure of that one first.
4. Run `git status`. A dirty working tree means the previous step has leftovers. Clear them first.

## Writing the spec

Target the first unchecked (`- [ ]`) step in the roadmap.

**Look up every fact before writing.** Never guess versions, the contents of official templates, or the structure of existing code. Query the npm registry, fetch a package and read it, run `nix eval`, read the files. Every factual claim in a spec needs verification.

The spec must contain:

- **Goal** — one sentence, stated as something observable: what must work for this step to be done
- **Why** — the background and the reasoning behind the design choices. This is the substance of the learning, and what separates a spec from a checklist
- **Files to write, and what goes in each** — filenames, required elements, constraints to satisfy. **Never write the code itself.** Naming a key, a type, or a function is specification; writing its value or body is implementation
- **Verification** — the exact commands the user runs, and the output to expect
- **A comprehension question** — one question whose answer you withhold. The user finds out and reports back
- **A suggested commit message**

Do not make the user memorize boilerplate. When a tool can generate a config file, it teaches more to have them generate it and then read it together than to dictate it.

## Filing the issue

1. Write the full spec to a temporary file
2. `gh issue create --title "Step N: <name>" --body-file <file>`
3. Report the issue number and URL to the user
4. **Also print the full spec in chat.** The issue is the record; chat is where the work happens

## Closing out

Once the user implements, verifies, commits, and pushes, `step-review` takes over. End the spec by saying so.

When the user gets stuck, do not jump to the answer. Give a graded hint first; give the answer only if that fails.
