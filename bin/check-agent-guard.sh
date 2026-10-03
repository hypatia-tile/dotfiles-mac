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
# Usage: bin/check-agent-guard.sh [--applies] [FILE...]
#        (the contract is in bin/lib/check.sh; any in-scope FILE runs every
#        case)
# Exit:  0 every case decided as expected; 1 otherwise
#
# The cases below are literal command strings as an agent would send them, so
# `$(…)` and `~` must reach the guard unexpanded.
# shellcheck disable=SC2016,SC2088
set -euo pipefail
# shellcheck source=lib/check.sh source-path=SCRIPTDIR
. "$(dirname "$0")/lib/check.sh"

scope bin/agent-guard.sh .claude/settings.json .codex/hooks.json \
  modules/common.nix '.cursor/*'
check_gate "$@"

guard="$PWD/bin/agent-guard.sh"
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
expect deny "sudo after a substitution word" "$(bash_call 'echo $(date)/x && sudo true')"
expect deny "sudo in backticks"            "$(bash_call 'echo `sudo whoami`')"
expect deny "sudo in nested substitution"  "$(bash_call 'echo "$(echo $(sudo whoami))"')"
expect deny "sudo after a quoted paren in a substitution" "$(bash_call $'x=$(echo \'")"\' && sudo true)')"
expect deny "sudo in a substitution nested in double quotes" "$(bash_call $'x=$(echo "$(echo \'")"\'; sudo true)")')"
expect deny "sudo expanded in an unquoted heredoc" "$(bash_call $'cat <<EOF\n$(sudo whoami)\nEOF')"
expect deny "unbalanced quotes"           "$(bash_call "echo 'unterminated")"
expect deny "command of unexpected shape" '{"tool_input":{"command":42}}'
expect deny "not JSON"                    'this is not json'

expect deny "codex: git push"               "$(codex_call 'touch MARKER && git push --dry-run .')"
expect deny "codex: sudo"                   "$(codex_call 'sudo -n true')"
expect deny "codex: patch into a legacy repo" "$(codex_patch "$(printf '*** Begin Patch\n*** Add File: %s/github/dotfiles/x\n+x\n*** End Patch\n' "$HOME")")"
expect deny "cursor: git push"              "$(cursor_call 'git push')"
expect deny "cursor: relative write, workspace is legacy" "$(cursor_call 'touch x' "$HOME/github/dotfiles")"

# Hook bypasses (ADR 0032). The hooks are the gates, so every way of running a
# commit without them is refused: the flag, the config that points Git
# elsewhere, the variables Lefthook skips on, and writes to the hooks
# themselves or to the untracked override that can switch them off.
expect deny "commit --no-verify"           "$(bash_call 'git commit --no-verify -m x')"
expect deny "commit -n"                    "$(bash_call 'git commit -n -m x')"
expect deny "commit -n in a cluster"       "$(bash_call 'git commit -anm x')"
expect deny "commit --no-verify abbreviated" "$(bash_call 'git commit --no-veri -m x')"
expect deny "merge --no-verify"            "$(bash_call 'git merge --no-verify feat/x')"
expect deny "push --no-verify"             "$(bash_call 'git push --no-verify')"
expect deny "git -c core.hooksPath"        "$(bash_call 'git -c core.hooksPath=/dev/null commit -m x')"
expect deny "git -c core.hooksPath, any case" "$(bash_call 'git -c CORE.HOOKSPATH=/tmp commit -m x')"
expect deny "git --config-env core.hooksPath" "$(bash_call 'git --config-env=core.hooksPath=H commit -m x')"
expect deny "config sets core.hooksPath"   "$(bash_call 'git config core.hooksPath /dev/null')"
expect deny "config --local sets core.hooksPath" "$(bash_call 'git config --local core.hooksPath .git/hooks')"
expect deny "config --unset core.hooksPath" "$(bash_call 'git config --unset core.hooksPath')"
expect deny "config set core.hooksPath"    "$(bash_call 'git config set core.hooksPath x')"
expect deny "config unset core.hooksPath"  "$(bash_call 'git config unset core.hooksPath')"
expect deny "config --edit"                "$(bash_call 'git config --edit')"
expect deny "LEFTHOOK=0"                   "$(bash_call 'LEFTHOOK=0 git commit -m x')"
expect deny "LEFTHOOK=false"               "$(bash_call 'LEFTHOOK=false git commit -m x')"
expect deny "LEFTHOOK_EXCLUDE through env" "$(bash_call 'env LEFTHOOK_EXCLUDE=secrets git commit -m x')"
expect deny "LEFTHOOK_CONFIG"              "$(bash_call 'LEFTHOOK_CONFIG=/tmp/empty.yml git commit -m x')"
expect deny "export LEFTHOOK=0"            "$(bash_call 'export LEFTHOOK=0 && git commit -m x')"
expect deny "bare assignment, then export" "$(bash_call 'LEFTHOOK=0; export LEFTHOOK; git commit -m x')"
expect deny "GIT_CONFIG_KEY core.hooksPath" "$(bash_call 'GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null git commit -m x')"
expect deny "GIT_CONFIG_PARAMETERS core.hooksPath" "$(bash_call "GIT_CONFIG_PARAMETERS=\"'core.hooksPath'='/dev/null'\" git commit -m x")"
expect deny "rm a hook stub"               "$(bash_call 'rm .githooks/pre-commit')"
expect deny "chmod a hook stub"            "$(bash_call 'chmod -x .githooks/pre-commit')"
expect deny "redirect into a hook stub"    "$(bash_call "echo 'exit 0' > .githooks/pre-commit")"
expect deny "cp into .git/hooks"           "$(bash_call 'cp /tmp/x .git/hooks/pre-commit')"
expect deny "sed -i on .git/config"        "$(bash_call "sed -i '' s/a/b/ .git/config")"
expect deny "write lefthook-local.yml"     "$(bash_call 'touch lefthook-local.yml')"
expect deny "git rm a hook stub"           "$(bash_call 'git rm .githooks/pre-commit')"
expect deny "Write a hook stub"            '{"tool_name":"Write","cwd":"/tmp/r","tool_input":{"file_path":"/tmp/r/.githooks/pre-commit","content":"exit 0"}}'
expect deny "Edit .git/config"             '{"tool_name":"Edit","cwd":"/tmp/r","tool_input":{"file_path":".git/config","old_string":"a","new_string":"b"}}'
expect deny "Write .config/lefthook-local.yml" '{"tool_name":"Write","cwd":"/tmp/r","tool_input":{"file_path":".config/lefthook-local.yml","content":"pre-commit:\n  skip: true"}}'
expect deny "patch adding a hook stub"     "$(codex_patch $'*** Begin Patch\n*** Add File: .githooks/pre-commit\n+exit 0\n*** End Patch\n')"
expect deny "codex: commit --no-verify"    "$(codex_call 'git commit --no-verify -m x')"
expect deny "cursor: LEFTHOOK=0"           "$(cursor_call 'LEFTHOOK=0 git commit -m x')"

# gh reaches the remote as git push does (#149): merging, writing through the
# API and changing the repository are the owner's.
expect deny "gh pr merge"                  "$(bash_call 'gh pr merge 148 --squash --delete-branch')"
expect deny "gh pr merge --auto"           "$(bash_call 'gh pr merge --auto --rebase 197')"
expect deny "gh pr merge with -R first"    "$(bash_call 'gh -R hypatia-tile/x pr merge 1')"
expect deny "gh pr merge with --repo before the verb" "$(bash_call 'gh pr --repo hypatia-tile/x merge 1')"
expect deny "gh pr merge by full path"     "$(bash_call '/opt/homebrew/bin/gh pr merge 1')"
expect deny "gh pr merge inside bash -c"   "$(bash_call "bash -c 'gh pr merge 1'")"
expect deny "gh pr merge after a check"    "$(bash_call 'gh pr checks 1 && gh pr merge 1 --squash')"
expect deny "gh api -X PUT contents"       "$(bash_call 'gh api -X PUT /repos/o/r/contents/a.md -f message=x -f content=eA==')"
expect deny "gh api --method=PUT merge"    "$(bash_call 'gh api --method=PUT /repos/o/r/pulls/1/merge')"
expect deny "gh api -XPOST"                "$(bash_call 'gh api -XPOST /repos/o/r/git/refs')"
expect deny "gh api -X delete, lower case" "$(bash_call 'gh api -X delete /repos/o/r/git/refs/heads/x')"
expect deny "gh api with a field is a POST" "$(bash_call 'gh api /repos/o/r/merges -f base=main -f head=feat/x')"
expect deny "gh api with --input is a POST" "$(bash_call 'gh api /repos/o/r/pulls/1/merge --input body.json')"
expect deny "gh api graphql mutation"      "$(bash_call "gh api graphql -f query='mutation { mergePullRequest(input: {pullRequestId: \"x\"}) { clientMutationId } }'")"
expect deny "gh api graphql query from a file" "$(bash_call 'gh api graphql -F query=@q.graphql')"
expect deny "gh repo sync"                 "$(bash_call 'gh repo sync')"
expect deny "gh repo edit"                 "$(bash_call 'gh repo edit --default-branch x')"
expect deny "gh release create"            "$(bash_call 'gh release create v1')"
expect deny "gh workflow run"              "$(bash_call 'gh workflow run update-flake-lock.yml')"
expect deny "gh secret set"                "$(bash_call 'gh secret set TOKEN')"
expect deny "gh auth token"                "$(bash_call 'gh auth token')"
expect deny "codex: gh pr merge"           "$(codex_call 'gh pr merge 1 --squash')"
expect deny "cursor: gh pr merge"          "$(cursor_call 'gh pr merge 1 --squash')"

# --- must ask ---------------------------------------------------------------
expect ask  "git commit"                  "$(bash_call 'git commit -m "feat: x"')"
expect ask  "git commit from a heredoc mentioning sudo and git push" \
  "$(bash_call $'git commit -F - <<\'EOF\'\nfix: never run sudo or git push from an agent\nEOF')"

expect ask  "cursor: git commit"            "$(cursor_call 'git commit -m x')"
expect ask  "commit whose message mentions --no-verify" "$(bash_call 'git commit -m "docs: never use --no-verify"')"
expect ask  "commit whose message is -n"     "$(bash_call 'git commit -m -n')"
expect ask  "commit with LEFTHOOK_OUTPUT, which only changes output" "$(bash_call 'LEFTHOOK_OUTPUT=summary git commit -m x')"
expect ask  "commit whose message names gh pr merge" "$(bash_call 'git commit -m "docs: the owner runs gh pr merge"')"
# A gh command on neither list is not allowed by default: a verb added later,
# or an alias that could expand to anything.
expect ask  "gh pr review"                 "$(bash_call 'gh pr review 1 --approve')"
expect ask  "gh pr close"                  "$(bash_call 'gh pr close 1')"
expect ask  "gh extension install"         "$(bash_call 'gh extension install o/gh-x')"
expect ask  "gh alias"                     "$(bash_call 'gh co 1')"
expect ask  "bare gh"                      "$(bash_call 'gh')"
expect allow "codex: unlisted gh (its own approval applies)" "$(codex_call 'gh pr review 1')"

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
expect allow "escaped backticks in double quotes" "$(bash_call 'grep -n "only \`link\`\|It is the only" docs/adr/0026-project-payloads-read-only.md')"
expect allow "substitution in single quotes is literal" "$(bash_call "echo '\$(sudo x)'")"
expect allow "quoted heredoc does not expand"  "$(bash_call $'cat <<\'EOF\'\n$(sudo whoami)\nEOF')"
expect allow "assignment from a substitution ending in /activate" "$(bash_call 'A=$(readlink -f result)/activate 2>/dev/null; echo "$A"')"
expect allow "unquoted substitution inside a word" "$(bash_call 'echo $(date)/activate')"
# A parenthesis inside quotes is text, not structure. Counting it ended the
# substitution in the wrong place and left an unbalanced quote behind, which
# `tokenize()` reported as "No closing quotation" — so the guard refused the
# jq idiom below while watching CI (#124).
expect allow "quoted backslash-paren in a substitution" "$(bash_call $'cur=$(echo "$s" | jq -r \'.[] | select(.bucket!="pending") | "\\(.name): \\(.bucket)"\' | sort)')"
expect allow "unbalanced open paren in a substitution" "$(bash_call $'x=$(jq -r \'"("\')')"
expect allow "unbalanced close paren in a substitution" "$(bash_call $'x=$(jq -r \'")"\')')"
expect allow "backslash-paren in double quotes in a substitution" "$(bash_call 'x=$(jq -r "\(.a)")')"
expect allow "substitution nested in double quotes, quoted parens" "$(bash_call $'x=$(echo "$(echo \'")"\')")')"
expect allow "comment mentioning sudo"    "$(bash_call 'ls # not sudo')"
expect allow "config reads core.hooksPath" "$(bash_call 'git config core.hooksPath')"
expect allow "config --get core.hooksPath" "$(bash_call 'git config --get core.hooksPath')"
expect allow "config get core.hooksPath"   "$(bash_call 'git config get core.hooksPath')"
expect allow "merge --no-verify-signatures" "$(bash_call 'git merge --no-verify-signatures feat/x')"
expect allow "log -n"                      "$(bash_call 'git log -n 5')"
expect allow "running a hook by hand"      "$(bash_call 'LEFTHOOK_VERBOSE=1 git hook run pre-commit')"
expect allow "reading a hook stub"         "$(bash_call 'cat .githooks/pre-commit .git/config')"
expect allow "copying a hook stub out"     "$(bash_call 'cp .githooks/pre-commit /tmp/x')"
expect allow "LEFTHOOK=0 only as text"     "$(bash_call 'echo "LEFTHOOK=0 is refused"')"
expect allow "grep for --no-verify"        "$(bash_call "grep -rn 'git commit --no-verify' docs/")"
expect allow "gh pr create"                "$(bash_call 'gh pr create --title "feat: x" --body-file /tmp/body.md')"
expect allow "gh pr checks"                "$(bash_call 'gh pr checks 1 --json name,bucket')"
expect allow "gh pr view"                  "$(bash_call 'gh pr view 1 --json mergeable')"
expect allow "gh pr checkout"              "$(bash_call 'gh pr checkout 197')"
expect allow "gh pr edit"                  "$(bash_call 'gh pr edit 1 --body-file /tmp/b.md')"
expect allow "gh run rerun --failed"       "$(bash_call 'gh run rerun 123 --failed')"
expect allow "gh issue list"               "$(bash_call 'gh issue list --state open')"
expect allow "gh issue create with -R"     "$(bash_call 'gh issue create -R hypatia-tile/x --label from-agent --title t --body b')"
expect allow "gh issue comment"            "$(bash_call 'gh issue comment 149 --body-file /tmp/c.md')"
expect allow "gh issue close"              "$(bash_call 'gh issue close 195 --comment "Superseded by #200."')"
expect allow "gh search"                   "$(bash_call 'gh search issues merge --repo o/r')"
expect allow "gh auth status"              "$(bash_call 'gh auth status')"
expect allow "gh api GET"                  "$(bash_call 'gh api repos/o/r/pulls/1/merge')"
expect allow "gh api -X GET with fields"   "$(bash_call 'gh api -X GET search/issues -f q=merge')"
expect allow "gh api with --jq naming a write" "$(bash_call "gh api repos/o/r/pulls --jq '.[] | select(.title | test(\"mutation\"))'")"
expect allow "gh api graphql query"        "$(bash_call "gh api graphql -f query='query { viewer { login } }'")"
expect allow "gh issue body naming gh pr merge" "$(bash_call "gh issue create --title x --body 'nothing stops gh pr merge or gh api -X PUT'")"
expect allow "grep for gh pr merge"        "$(bash_call "grep -rn 'gh pr merge' .claude/skills")"
expect allow "echo of gh pr merge"         "$(bash_call 'echo "run: ! gh pr merge 1 --squash"')"
expect allow "editing the tracked lefthook.yml" '{"tool_name":"Edit","cwd":"/tmp/r","tool_input":{"file_path":"lefthook.yml","old_string":"a","new_string":"b"}}'

# --- registrations (ADR 0027) ------------------------------------------------
# The cases above prove the script decides correctly; these prove the agents
# will actually run it. Each is a measured requirement rather than taste.
root=$PWD
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
