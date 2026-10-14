---
name: inbox
description: Record an idea in this repository's inbox issue as one English comment, and triage the inbox together with the roadmap — promoting entries to issues, superseding the inbox, and rebuilding the roadmap issue. Use when the owner has an idea worth keeping that is not an issue yet, or asks to triage the inbox or update the roadmap. The owner may phrase this in Japanese ("メモしておいて", "inboxに入れて", "roadmapを更新して").
---

# inbox

Record an idea before it is ready to be an issue, and turn the inbox into
issues and a roadmap at triage (ADR 0035).

The two issues have separate jobs. The **inbox** holds ideas that have not
yet become anything. The **roadmap** orders open issues and nothing else. One
idea is never in both.

## Find the current issues

```sh
gh issue list --state open --search 'Inbox in:title' --json number,title \
  -q '.[] | select(.title | startswith("Inbox (")) | .number'
gh issue list --state open --search 'Roadmap in:title' --json number,title \
  -q '.[] | select(.title | startswith("Roadmap:")) | .number'
```

The `select` is needed: GitHub's search ignores punctuation, and any issue
that mentions an inbox in its title also matches. Each command should print
exactly one number. If either prints several, report it and stop; do not
guess which one is current. No inbox at all is normal only before the first
triage: that triage opens the first inbox, without a `Supersedes` line, and an
idea waits for it.

## Record an idea

1. **Spar briefly if the idea is vague.** Two or three exchanges to find what
   the owner actually wants to do. This is not `grilling`: settle what the
   idea is, not how to do it.
2. **Check it is new.** Search the open issues and the inbox's body and
   comments. If an issue already covers it, say so instead of recording it.
3. **Write the comment in English.** The first line is one sentence saying
   what to do. Below it, optionally: where it came up, why it matters, any
   fact already checked (cite the file, commit or issue). Keep it short; the
   researched write-up happens at promotion, if ever.
4. **Post it:** `gh issue comment <inbox> --body-file <file>`, and report the
   comment's URL.

Nothing else happens here: no issue, no branch, no edit.

## Triage

Run it with each roadmap rebuild, or when the owner asks.

1. **Read the inbox:** the entries carried over in its body, and every comment.
2. **Propose an outcome for each entry**, in one table:
   - **promote**: it becomes an issue;
   - **done**: it has already happened (cite the PR or commit);
   - **drop**: it is no longer wanted (one-line reason);
   - **keep**: it is carried over unchanged.

   The owner decides. Do not act on an entry before the owner answers.
3. **Promote.** Write each issue in this repository's usual form: the problem,
   what is known, what needs deciding, done-when, sized to what is known.
   Link the inbox comment it came from. An idea that will need an ADR
   becomes an issue first, and `adr-new` cites it.
4. **Open the new inbox** with the title `Inbox (YYYY-MM-DD)`. Its body:
   - `Supersedes #<old>.`;
   - three lines on how to use it: one comment per idea, in English, with the
     first line saying what to do (ADR 0035);
   - every **keep** entry, as its first line followed by a link to the
     original comment.
5. **Close the old inbox** with a comment that lists every entry's outcome
   (`→ #N`, `done in #N`, `dropped: <reason>`, `carried to #<new>`), then run
   `gh issue close <old> --reason completed`.
6. **Rebuild the roadmap** as a new issue titled
   `Roadmap: order of work across the open issues (YYYY-MM-DD)`. Its body:
   - opens with `Supersedes #<old>`, the date and the `origin/main` commit;
   - has a section on what changed since the old roadmap;
   - lists open issues only, in numbered sections ordered by when to take them
     up, each item naming its dependencies;
   - ends with one line pointing to the inbox for ideas that are not issues.

   Close the old roadmap with `Superseded by #<new>, which …` and
   `--reason completed`.

## Rules

- **Never edit an existing issue body or comment;** supersede instead.
  `agent-guard` refuses the `gh api` writes that editing a comment needs, and
  an edit hides what changed.
- **English** in every comment and issue, like every other artifact.
- **The owner decides every outcome** at triage. Recording an idea needs only
  their request.
- Pinning is the owner's: `gh issue pin` is not in `agent-guard`'s allowlist,
  which is why the issues are found by title.
- Nothing in this skill touches the working tree or commits.
