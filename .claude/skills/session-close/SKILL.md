---
name: session-close
description: End a session in this repository so that the next one starts stateless — a retrospective with the owner, a review of the agent's memory note by note, recording what both produced in the inbox (and the roadmap if the order changed), then confirming the checkout and GitHub are in a state the next session can start from. Use when the owner wants to end, wrap up or look back on a session. The owner may phrase this in Japanese ("セッションを終えたい", "振り返りをしましょう", "メモリの整理").
---

# session-close

End a session **stateless**: the next session needs nothing from this one
that is not in the repository or its issues (#271). Whatever this session
learned is either written there or deliberately let go.

The order matters. The retrospective and the memory review are where new
ideas and lessons appear, so recording comes after them. Run the other way,
their results have nowhere to go but a second pass.

## Steps

1. **Retrospective, with the owner.**
   - Ask the owner what worked, what cost time, and what was confusing,
     the conversation itself included.
   - Bring your own list: corrections made this session, a claim you had
     to take back, a step that failed and why, a rule that was unclear.
     Cite the commit, PR or comment for each.
   - Agree on what each point becomes: an inbox entry, a comment on an
     open issue it belongs to, or nothing. Nothing is recorded yet.
2. **Review the agent's memory, note by note, with the owner.** For Claude
   Code this is every file in `~/.claude/projects/<project>/memory/`, where
   `<project>` is the checkout's absolute path with each `/` and `.` turned
   into `-`. `MEMORY.md` is included, and so are notes written this
   session. For each
   note, propose one outcome and let the owner decide:
   - **move**: its content goes into the repository or an issue, then the
     note is deleted;
   - **delete**: it is stale, or already written down elsewhere (cite
     where);
   - **keep for convenience**: allowed only when the same content is in the
     repository or an issue. The note names that place, so that it can go
     when the place is updated.

   **Memory is never the only copy.** A note that would be the only record
   of something is moved, not kept. Check a note's claims against the
   current tree before proposing to move it; memory reflects when it was
   written.
3. **Record what steps 1 and 2 produced.**
   - New ideas and lessons go to the inbox through `inbox`, one comment
     each. Something that belongs to an open issue is a comment there.
   - If the owner asks for triage, or something recorded changes the order
     of work, run `inbox`'s triage, which rebuilds the roadmap.
   - Then delete the notes decided in step 2, and update `MEMORY.md`.
4. **Confirm the session can end.** Check each, and report it:
   - the checkout is on `main`, the tree is clean, and `main` matches
     `origin/main` after a fetch;
   - no local branch holds commits that are on no remote branch
     (`git log --branches --not --remotes --oneline` prints nothing);
   - no open PR of this session is waiting on the owner
     (`gh pr list --author @me`);
   - no background task or wait of this session is still running;
   - merged changes that need a `darwin-rebuild switch` are named, since a
     merged change is not an applied one.

   Anything that fails is either finished now, with the owner, or recorded
   in an issue. It is never left to be remembered.
5. **Report**: each outcome of steps 1 and 2 with where it was recorded
   (comment or issue URL), the memory notes left and the place each one
   points to, and the result of each check in step 4.

## Rules

- The owner decides every memory outcome and what the retrospective records.
  Propose; do not act first.
- Never push, merge or switch (ADR 0003, ADR 0036). A step 4 failure that
  needs one is handed to the owner.
- Posting follows `inbox`'s rules: English, and existing issue bodies and
  comments are never edited.
