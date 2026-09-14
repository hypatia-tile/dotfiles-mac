---
name: step-review
description: Review a committed step of a hand-written learning project. Pins the review to a commit hash, reads the actual contents, and records findings as a comment on the step's GitHub issue. Use when the user asks for a review, or reports that a step is finished; the user may phrase this in Japanese.
---

Review one step of a learning project. **This skill never writes code.** It reports findings; the user fixes them.

## Before reviewing

1. Run `git status`. **If anything is uncommitted, do not start the review.** A review is pinned to a hash, so uncommitted work cannot be reviewed. Ask the user to commit first.
2. Read the working contract in `docs/roadmap.md` and follow that repository's division of labor.
3. Run `gh issue list --state open` to find the issue this work belongs to.
4. Pin the target: use `git log --oneline` to select the commits for this issue (there may be more than one). Express a range as `base..head`.
5. Check that the commits are pushed. If not, ask the user to push — an unpushed hash does not resolve as a link from the issue comment.

## Read the actual thing

**Never review from assumption.** Read the target commits with `git show` and by reading the files directly.

Verify what can be verified: whether the generated artifacts are what was intended, what the config values actually resolved to, which dependency versions actually landed. Read-only commands are yours to run. Never write a finding that rests on "this is probably how it turned out."

## Writing findings

Sort findings into three tiers:

- **Must fix** — real harm. It causes an incident if left alone, or it breaks a later step. State the concrete failure scenario
- **Your call** — not wrong, but the user should be able to articulate why they chose it. Give both sides of the trade-off
- **Minor** — a matter of taste. Say explicitly that it need not be fixed

Every finding states why it is a problem and what direction the fix goes. **Never write the fix.** Stop at the direction.

**Always state what was done right**, backed by something you verified — not as praise, but because naming what worked is part of the review's job and part of the learning.

Never repeat a finding. If something raised last time is still unfixed, mention it in one line as a leftover.

## Recording

1. **Open the comment body with the reviewed hash** (`Reviewed: abc1234` or `abc1234..def5678`)
2. `gh issue comment <number> --body-file <file>`
3. Print the same content in chat

## Closing

- **Do not close the issue while any must-fix finding remains.** Have the user stack fix commits, then add a follow-up comment naming those hashes
- Once everything is resolved, post a closing comment and run `gh issue close <number>`
- Tick the step in `docs/roadmap.md` if the repository's contract puts the roadmap in the AI's hands

**Never let the user amend.** Fixes go in new commits — amending orphans the hash the review comment points at.
