#!/usr/bin/env bash
# Exercise bin/agent-guard.sh against the calls it must refuse and the calls it
# must not (ADR 0027).
#
# The second list matters as much as the first. A guard that denies too much
# stops legitimate work in every agent at once, and the likeliest false
# positive in this repository is prose: commit messages, ADRs and issue bodies
# that mention `sudo` or `git push` by name. Those cases are here so a looser
# pattern cannot land without failing.
#
# Usage: bin/check-agent-guard.sh
# Exit:  0 every case decided as expected; 1 otherwise
#
# The cases below are literal command strings as an agent would send them, so
# `$(…)` and `~` must reach the guard unexpanded.
# shellcheck disable=SC2016,SC2088
set -euo pipefail

guard="$(cd "$(dirname "$0")" && pwd)/agent-guard.sh"
fail=0
total=0

# expect <allow|deny|ask> <label> <hook JSON>
expect() {
  local want=$1 label=$2 json=$3 out got
  total=$((total + 1))
  out=$(printf '%s' "$json" | "$guard")
  if [[ -z $out ]]; then
    got=allow
  elif ! printf '%s' "$out" | jq -e '(keys == ["hookSpecificOutput"]) and ((.hookSpecificOutput | keys) - ["hookEventName","permissionDecision","permissionDecisionReason"] == [])' >/dev/null 2>&1; then
    # Codex validates the answer with additionalProperties false: any other
    # key and it discards the decision and runs the command (measured; ADR 0027).
    got="malformed output (extra keys)"
  else
    got=$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // "malformed"')
  fi
  if [[ $got != "$want" ]]; then
    echo "FAIL  want $want, got $got: $label" >&2
    [[ -n $out ]] && echo "      $out" >&2
    fail=1
  fi
}

# Shapes captured from the real agents (Codex 0.154.0, cursor-agent
# 2026.08.31), trimmed to the fields the guard reads.
codex_call() { jq -cn --arg c "$1" --arg d "${2:-/tmp}" '{hook_event_name:"PreToolUse",turn_id:"t",permission_mode:"default",tool_name:"Bash",cwd:$d,tool_input:{command:$c}}'; }
codex_patch() { jq -cn --arg c "$1" '{hook_event_name:"PreToolUse",turn_id:"t",tool_name:"apply_patch",cwd:"/tmp",tool_input:{command:$c}}'; }
cursor_call() { jq -cn --arg c "$1" --arg r "${2:-/tmp}" '{hook_event_name:"preToolUse",cursor_version:"2026.08.31",tool_name:"Shell",cwd:"",workspace_roots:[$r],tool_input:{command:$c,cwd:"",timeout:30000}}'; }

bash_call() { jq -cn --arg c "$1" --arg d "${2:-/tmp}" '{hook_event_name:"PreToolUse",tool_name:"Bash",cwd:$d,tool_input:{command:$c}}'; }

# --- must deny --------------------------------------------------------------
expect deny "sudo alone"                  "$(bash_call 'sudo true')"
expect deny "sudo later in a chain"       "$(bash_call 'ls && sudo rm -rf /tmp/x')"
expect deny "sudo behind env assignment"  "$(bash_call 'FOO=1 sudo true')"
expect deny "sudo inside bash -c"         "$(bash_call "bash -c 'sudo true'")"
expect deny "sudo in command substitution" "$(bash_call 'echo "$(sudo whoami)"')"
expect deny "sudo in a heredoc fed to bash" "$(bash_call $'bash <<\'EOF\'\nsudo true\nEOF')"
expect deny "darwin-rebuild switch"       "$(bash_call 'darwin-rebuild switch --flake .#Kazukis-MacBook-Air')"
expect deny "darwin-rebuild activate"     "$(bash_call 'darwin-rebuild activate')"
expect deny "activation script"           "$(bash_call './result/activate')"
expect deny "git push"                    "$(bash_call 'git push -u origin feat/x')"
expect deny "git -C dir push"             "$(bash_call 'git -C /tmp/repo push')"
expect deny "nix flake update"            "$(bash_call 'nix flake update')"
expect deny "legacy dot-link.sh"          "$(bash_call '~/github/dotfiles/bin/dot-link.sh')"
expect deny "legacy dot-link.sh via bash" "$(bash_call 'bash ~/github/dotfiles/bin/dot-link.sh')"
expect deny "rm in a legacy repo"         "$(bash_call 'rm -rf ~/github/nix-darwin/flake.nix')"
expect deny "cd legacy then relative rm"  "$(bash_call 'cd ~/github/dotfiles && rm README.md')"
expect deny "relative write, cwd legacy"  "$(bash_call 'touch x' "$HOME/github/dotfiles")"
expect deny "cp into a legacy repo"       "$(bash_call 'cp /tmp/a ~/github/dotfiles/a')"
expect deny "mv out of a legacy repo"     "$(bash_call 'mv ~/github/dotfiles/a /tmp/a')"
expect deny "redirect into a legacy repo" "$(bash_call 'echo x > ~/github/dotfiles/a')"
expect deny "sed -i in a legacy repo"     "$(bash_call "sed -i '' s/a/b/ ~/github/dotfiles/a")"
expect deny "git commit in a legacy repo" "$(bash_call 'git -C ~/github/dotfiles commit -m x')"
expect deny "Write into a legacy repo"    "$(jq -cn --arg p "$HOME/github/dotfiles/x" '{tool_name:"Write",cwd:"/tmp",tool_input:{file_path:$p,content:"x"}}')"
expect deny "Edit into a legacy repo"     "$(jq -cn --arg p "$HOME/github/nix-darwin/x" '{tool_name:"Edit",cwd:"/tmp",tool_input:{file_path:$p,old_string:"a",new_string:"b"}}')"
expect deny "patch into a legacy repo"    "$(jq -cn --arg p "$HOME/github/dotfiles/x" '{tool_name:"apply_patch",cwd:"/tmp",tool_input:{input:("*** Begin Patch\n*** Update File: "+$p+"\n*** End Patch")}}')"
expect deny "argv-form command"           '{"tool_name":"shell","cwd":"/tmp","tool_input":{"command":["sudo","true"]}}'
expect deny "top-level command (cursor)"  '{"hook_event_name":"beforeShellExecution","cwd":"/tmp","command":"git push"}'
expect deny "flake ref with # before git push" "$(bash_call 'nix build .#Kazukis-MacBook-Air && git push')"
expect deny "# inside a word before sudo"  "$(bash_call 'echo a#b; sudo true')"
expect deny "comment line then sudo"       "$(bash_call $'ls # just listing\nsudo true')"
expect deny "sudo on a second line"        "$(bash_call $'ls\nsudo true')"
expect deny "sudo after a line continuation" "$(bash_call $'ls \\\n && sudo true')"
expect deny "unbalanced quotes"           "$(bash_call "echo 'unterminated")"
expect deny "command of unexpected shape" '{"tool_input":{"command":42}}'
expect deny "not JSON"                    'this is not json'

expect deny "codex: git push"               "$(codex_call 'touch MARKER && git push --dry-run .')"
expect deny "codex: sudo"                   "$(codex_call 'sudo -n true')"
expect deny "codex: patch into a legacy repo" "$(codex_patch "$(printf '*** Begin Patch\n*** Add File: %s/github/dotfiles/x\n+x\n*** End Patch\n' "$HOME")")"
expect deny "cursor: git push"              "$(cursor_call 'git push')"
expect deny "cursor: relative write, workspace is legacy" "$(cursor_call 'touch x' "$HOME/github/dotfiles")"

# --- must ask ---------------------------------------------------------------
expect ask  "git commit"                  "$(bash_call 'git commit -m "feat: x"')"
expect ask  "git commit from a heredoc mentioning sudo and git push" \
  "$(bash_call $'git commit -F - <<\'EOF\'\nfix: never run sudo or git push from an agent\nEOF')"

expect ask  "cursor: git commit"            "$(cursor_call 'git commit -m x')"

# --- must allow -------------------------------------------------------------
expect allow "git status"                 "$(bash_call 'git status --short')"
expect allow "darwin-rebuild build"       "$(bash_call 'darwin-rebuild build --flake .')"
expect allow "nix flake check"            "$(bash_call 'nix flake check --no-update-lock-file')"
expect allow "sudo only inside a quoted argument" "$(bash_call 'echo "hand sudo steps to the owner"')"
expect allow "git push only inside grep"  "$(bash_call "grep -rn 'git push' docs/")"
expect allow "gh pr create body mentions sudo" "$(bash_call "gh pr create --title x --body 'never sudo'")"
expect allow "python heredoc mentioning sudo" "$(bash_call $'python3 - <<\'PY\'\nprint("sudo")\nPY')"
expect allow "reading a legacy repo"      "$(bash_call 'cat ~/github/dotfiles/README.md')"
expect allow "git log in a legacy repo"   "$(bash_call 'git -C ~/github/dotfiles log --oneline')"
expect allow "cp out of a legacy repo"    "$(bash_call 'cp ~/github/dotfiles/a /tmp/a')"
expect allow "Read of a legacy file"      "$(jq -cn --arg p "$HOME/github/dotfiles/x" '{tool_name:"Read",cwd:"/tmp",tool_input:{file_path:$p}}')"
expect allow "Write elsewhere"            '{"tool_name":"Write","cwd":"/tmp","tool_input":{"file_path":"/tmp/x","content":"sudo git push"}}'
expect allow "no command, no path"        '{"tool_name":"Grep","cwd":"/tmp","tool_input":{"pattern":"sudo"}}'
expect allow "hash inside quotes is not a comment" "$(bash_call "echo '# sudo' && git status")"
expect allow "flake ref alone"             "$(bash_call 'nix build .#darwinConfigurations.Kazukis-MacBook-Air.system --no-update-lock-file')"
expect allow "codex: git commit (no ask in Codex; its own approval applies)" "$(codex_call 'git commit -m x')"
expect allow "codex: patch with a quote in it" "$(codex_patch $'*** Begin Patch\n*** Add File: notes.md\n+it\'s fine, don\'t worry\n*** End Patch\n')"
expect allow "codex: plain command"          "$(codex_call 'git status')"
expect allow "cursor: read"                  '{"hook_event_name":"preToolUse","cursor_version":"x","tool_name":"Read","workspace_roots":["/tmp"],"tool_input":{"file_path":"/tmp/x"}}'
expect allow "comment mentioning sudo"    "$(bash_call 'ls # not sudo')"

# --- registrations (ADR 0027) ------------------------------------------------
# The cases above prove the script decides correctly; these prove the agents
# will actually run it. Each is a measured requirement rather than taste.
root="$(cd "$(dirname "$0")/.." && pwd)"
registered() { jq -e --arg c "$2" '[.. | objects | select(.type? == "command") | .command] | index($c) != null' "$1" >/dev/null 2>&1; }

total=$((total + 1))
# shellcheck disable=SC2016 # the literal variable is what Claude Code expands
if ! registered "$root/.claude/settings.json" '"$CLAUDE_PROJECT_DIR"/bin/agent-guard.sh'; then
  echo "FAIL  .claude/settings.json does not register the guard (Claude Code and cursor-agent)" >&2
  fail=1
fi

total=$((total + 1))
checkout=$(sed -n 's/^[[:space:]]*checkoutPath = "\([^"]*\)";.*/\1/p' "$root/modules/common.nix")
if [[ -z $checkout ]] || ! registered "$root/.codex/hooks.json" "$checkout/bin/agent-guard.sh"; then
  echo "FAIL  .codex/hooks.json does not register the guard at checkoutPath ($checkout)" >&2
  fail=1
fi

total=$((total + 1))
# cursor-agent runs Claude's project hooks as well as its own: a registration
# here too made it run the guard twice per call (measured).
if [[ -e $root/.cursor/hooks.json ]]; then
  echo "FAIL  .cursor/hooks.json exists; cursor-agent already runs the guard via .claude/settings.json" >&2
  fail=1
fi

if [[ $fail -ne 0 ]]; then
  exit 1
fi
echo "check-agent-guard: $total cases decided as expected"
