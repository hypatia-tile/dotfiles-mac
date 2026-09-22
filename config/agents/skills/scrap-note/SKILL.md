---
name: scrap-note
description: Record a piece of general, publicly shareable knowledge in the owner's scrap notes repository — one file per topic, indexed, and written so it can be read back months later. Use when the owner asks to note, save, write down or keep something learned, or says it belongs in scrap. The owner may phrase this in Japanese.
argument-hint: "What was learned?"
---

# Writing a note in scrap

`hypatia-tile/scrap` is the owner's store for knowledge that outlives the
project it was learned in. A note there is read back on its own, long after
the session that produced it, by someone who no longer remembers the context
— so it has to stand without one.

The repository is at `~/ghqrepo/github.com/hypatia-tile/scrap`. If it is not
there, `ghq get hypatia-tile/scrap`. **It is public.**

## What belongs here

Three tests, all of which must pass.

- **General.** It still holds in a repository you have never seen. A fact
  about how macOS, Nix, git or a language behaves qualifies; "our CI skips
  the build job for payload-only changes" does not — that belongs to the
  project, next to the thing it explains.
- **Publicly shareable.** No secrets, no credentials, no internal hostnames,
  no employer specifics, no personal paths beyond `$HOME`-relative ones.
  Anyone can read this repository.
- **It cost something.** Something misleading, non-obvious, or contradicted
  by the intuitive reading. A fact plainly stated in the first paragraph of
  `man` is not worth a note; the reason the documented thing does not work
  the way it reads is.

Work that is merely *not done yet* is not knowledge — that is an issue in
the repository it belongs to.

When a lesson has both a general half and a project-specific half, split it.
The general half goes here; the specific half stays in the project, where the
code it constrains can be seen next to it.

## Write only what was confirmed

The value of a note is that it can be trusted without re-deriving it. That
survives only if the line between *checked* and *assumed* is drawn in the
note itself.

- State what was actually observed in the session, and prefer showing the
  evidence — the command, the value it printed — over asserting the
  conclusion.
- Where a claim was reasoned rather than measured, **say so in the note** and
  name what would settle it. A note that admits one uncertain line is worth
  more than one that hides it, because everything else in it becomes
  believable.
- Never pad a note with background recalled from training. If it was not
  confirmed and is not needed, leave it out.

## Shape

One file per topic, under a category directory: `macos/`, `nix/`, `git/`.
The filename is the topic, not the date — a note is found by what it is
about.

**Look for an existing note first.** A new note on a topic already covered
splits the knowledge in two, and the reader finds whichever one they find.
Extend the existing file instead; replace a line that turned out to be wrong
rather than appending a correction after it.

Then **add it to the `README.md` index**, under its category, one line with a
hook saying what the note answers. A note missing from the index is a note
the owner will not find.

Write English: the repository is public and its README and prose are English.
This holds even when the conversation is Japanese.

Open with what the thing *is* in a sentence or two, then the part that
misleads. Keep headings scannable — the reader is usually looking for one
paragraph, not reading the file.

## Finishing

Commit, with a message naming what the note records rather than "add note".

**Never push.** The owner pushes, as everywhere else. Say the note is
committed and leave the push to them.
