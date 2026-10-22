#!/usr/bin/env zsh

# `def WORD...`: look a word or phrase up in the offline dictionary server
# (the dictd launchd agent in modules/home/base.nix, #286), WordNet first and
# then English Wiktionary, in a pager. With no entry in either, it lists
# near spellings instead.

# Wiktionary's text keeps its wiki templates (`{{ng|...}}`) and lists every
# language that has the headword. This keeps an entry only if it has an
# English section, drops the other languages, and unwraps the templates that
# carry the text, dropping the rest. Templates nest and span wrapped lines,
# so it reads a whole entry before it rewrites one.
_def_clean_wiktionary=$(cat <<'AWK'
function join(a, from, to, sep,   s, i) {
  s = ""
  for (i = from; i <= to; i++) if (a[i] != "" && a[i] !~ /=/ && a[i] != "_") s = s (s == "" ? "" : sep) a[i]
  return s
}
function expand(t,   n, p, name) {
  n = split(t, p, "|"); name = p[1]
  if (name == "ng" || name == "n-g" || name == "non-gloss") return p[2]
  if (name == "gloss" || name == "gl") return "(" p[2] ")"
  if (name == "q" || name == "qual" || name == "qualifier" || name == "i") return "(" join(p, 2, n, ", ") ")"
  if (name == "lb" || name == "lbl") return "(" join(p, 3, n, ", ") ")"
  if (name == "ux" || name == "uxi") return p[3] (n >= 4 && p[4] !~ /=/ ? " (" p[4] ")" : "")
  if (name == "syn" || name == "ant") return (name == "syn" ? "Synonyms: " : "Antonyms: ") join(p, 3, n, ", ")
  # Form-of templates: {{plural of|en|mouse}} is "plural of mouse".
  if (name ~ / of$/) return name " " p[3]
  return ""
}
function untemplate(s,   out, depth, buf, i, c) {
  out = ""; depth = 0
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 2)
    if (c == "{{") { depth++; buf[depth] = ""; i++; continue }
    if (c == "}}" && depth > 0) {
      c = expand(buf[depth]); depth--; i++
      if (depth > 0) buf[depth] = buf[depth] c; else out = out c
      continue
    }
    c = substr(s, i, 1)
    if (depth > 0) buf[depth] = buf[depth] c; else out = out c
  }
  return out
}
function flush(   s, n, l, i, kept, lang, english) {
  if (entry == "") return
  # macOS awk's split() also splits on newlines, whatever the separator, so
  # the template parameters must not contain one while expand() splits them.
  s = entry; gsub(/\n/, "\001", s); s = untemplate(s); gsub(/\001/, "\n", s)
  n = split(s, l, "\n"); kept = ""; english = 0; lang = ""
  for (i = 1; i <= n; i++) {
    if (l[i] ~ /^    [^ ]/) { lang = substr(l[i], 5); if (lang == "English") english = 1 }
    if (l[i] !~ /^    / || lang == "English") {
      # A line that held nothing but templates is dropped.
      if (l[i] == "" || l[i] !~ /^[ *:]*([0-9]+\.)? *$/) kept = kept l[i] "\n"
    }
  }
  if (english) printf "%s", kept
  entry = ""
}
/^From / { flush() }
/^[0-9]+ definitions? found$/ { next }
{ entry = entry $0 "\n" }
END { flush() }
AWK
)

def() {
  if (( $# == 0 )); then
    print -u2 "usage: def WORD..."
    return 2
  fi
  local word="$*" host=127.0.0.1 wn wk near
  # WordNet joins the words of a phrase with underscores (`carry_out`).
  wn=$(dict -h $host -d wn "${word// /_}" 2>/dev/null)
  wk=$(dict -h $host -d wiktionary "$word" 2>/dev/null | awk "$_def_clean_wiktionary")
  if [[ -z $wn && -z $wk ]]; then
    if ! dict -h $host -D >/dev/null 2>&1; then
      print -u2 "def: no dictionary server on $host (the dictd launchd agent)"
      return 1
    fi
    near=$(dict -h $host -m -s lev "$word" 2>/dev/null)
    if [[ -n $near ]]; then
      print -r -- "No entry for \"$word\". Near spellings:"$'\n'"$near"
    else
      print -r -- "No entry for \"$word\", and no near spelling."
    fi
    return 1
  fi
  print -r -- "${wn#*$'\n'}"$'\n'"$wk" | less -FRX
}
