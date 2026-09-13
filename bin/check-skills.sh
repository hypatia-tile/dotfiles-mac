#!/usr/bin/env bash
# Validate this repository's skill tree.
#
# The failures caught here are the silent kind. A skill with no description is
# never surfaced to the model, and a `name` that disagrees with its directory
# is invoked under one spelling and stored under another. Neither produces an
# error at run time — the skill is simply never used, and nothing says so.
#
# The validator is ported from hypatia-tile/skills (MIT, same owner), which
# runs it over the user-scope skills in `~/.claude/skills`. It is copied rather
# than consumed as a flake input on purpose: an input would put it in the store
# and gate every fix behind a lock bump, which ADR 0011 confines to dedicated
# commits, and `nix flake check` is behind a path filter that a skill-only
# change does not trip anyway. Seventy lines of bash is the cheaper dependency.
#
# One check here has no counterpart there. Skills in this repository are
# tracked through a `.gitignore` allowlist (`.claude/skills/*` ignored, one
# `!.claude/skills/<name>` per tracked skill), so a new skill that nobody
# allowlists is silently untracked — it works on this machine, is absent from
# every clone, and `git status` stays clean. CLAUDE.md names that trap; this is
# what makes it fire.
#
# Usage: bin/check-skills.sh [skills-dir]   (default: .claude/skills)
# Exit:  0 the tree is sound; 1 a skill is broken, untracked, or missing
set -euo pipefail

root="${1:-.claude/skills}"

if [[ ! -d $root ]]; then
  echo "error: $root is not a directory" >&2
  exit 1
fi

# The tracking check needs an index to consult. Outside a work tree — a store
# copy, an extracted tarball — the rest of the validation is still meaningful,
# so degrade to it rather than refusing to run, and say which check was lost.
tracked=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  tracked="$(git ls-files "$root")"
else
  echo "note: not a git work tree, skipping the allowlist check" >&2
fi

fail=0
found=0

shopt -s nullglob
for dir in "$root"/*/; do
  found=$((found + 1))
  slug="$(basename "$dir")"
  file="$dir/SKILL.md"

  if [[ ! -f $file ]]; then
    echo "error: $slug: SKILL.md is missing" >&2
    fail=1
    continue
  fi

  if [[ -n $tracked ]] && ! printf '%s\n' "$tracked" | grep -qxF "$root/$slug/SKILL.md"; then
    echo "error: $slug: not tracked — add '!$root/$slug' to .gitignore" >&2
    fail=1
  fi

  if [[ "$(head -n 1 "$file")" != "---" ]]; then
    echo "error: $slug/SKILL.md: does not open with YAML frontmatter" >&2
    fail=1
    continue
  fi

  frontmatter="$(awk 'NR == 1 { next } /^---[[:space:]]*$/ { exit } { print }' "$file")"
  name="$(printf '%s\n' "$frontmatter" | sed -n 's/^name:[[:space:]]*//p' | head -n 1)"
  description="$(printf '%s\n' "$frontmatter" | sed -n 's/^description:[[:space:]]*//p' | head -n 1)"

  # No duplicate-name check, deliberately. The upstream script carries one,
  # but it cannot fire: reaching it requires `name` to equal the directory
  # basename, and two directories under one parent cannot share a basename.
  # Requiring the match is what makes uniqueness a property of the filesystem
  # rather than something to verify.
  if [[ -z $name ]]; then
    echo "error: $slug/SKILL.md: frontmatter has no 'name'" >&2
    fail=1
  elif [[ $name != "$slug" ]]; then
    echo "error: $slug/SKILL.md: name '$name' does not match its directory" >&2
    fail=1
  fi

  if [[ -z $description ]]; then
    echo "error: $slug/SKILL.md: frontmatter has no 'description'" >&2
    fail=1
  fi
done

if [[ $found -eq 0 ]]; then
  echo "error: no skills found under $root" >&2
  fail=1
fi

if [[ $fail -ne 0 ]]; then
  exit 1
fi

echo "check-skills: $found skills validated"
