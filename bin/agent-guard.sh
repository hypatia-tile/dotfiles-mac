#!/usr/bin/env bash
# Pre-tool-use guard for every agent working in this repository (ADR 0027).
#
# Registered as a project hook for Claude Code (.claude/settings.json) and
# Codex (.codex/hooks.json); cursor-agent reads the Claude registration. The
# deny list below is the only place the AGENTS.md hard rules are enforced as
# code — .claude/settings.json keeps a subset as a second layer for Claude.
#
# Reads the hook's JSON on stdin. Allowing prints nothing: answering "allow"
# would skip the agent's own permission prompt, which is not ours to skip.
# Denying and asking print exactly one object, {"hookSpecificOutput": {...}},
# and nothing else. That is measured, not a style choice: Codex validates the
# output with additionalProperties false, so a single extra key made it treat
# a denial as invalid output and run the command anyway. cursor-agent
# translates this Claude-form answer itself.
#
# Codex has no "ask" ("unsupported permissionDecision:ask"), so a call that
# would ask is allowed there and left to Codex's own approval flow (ADR 0027).
#
# Decides from what the call carries, not what the tool is called: a `command`
# is analysed as shell, and a path accompanied by content to write is a write.
# A guarded call it cannot parse is denied, and so is any error of its own —
# Claude Code and Codex treat a crashing hook as non-blocking, so failing
# closed has to be done here rather than left to the agent.
#
# Usage: <hook JSON on stdin> | bin/agent-guard.sh
# Exit:  always 0; the decision is in the output.
set -uo pipefail

deny() {
  local reason=${1//\\/\\\\}
  reason=${reason//\"/\\\"}
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"agent-guard: %s"}}\n' "$reason"
  exit 0
}

input=$(mktemp "${TMPDIR:-/tmp}/agent-guard.XXXXXX") || deny "could not create a temporary file"
trap 'rm -f "$input"' EXIT
trap 'deny "internal error; refusing rather than failing open"' ERR
cat >"$input"

command -v python3 >/dev/null 2>&1 || deny "python3 is not available, so the call cannot be checked"

read -r -d '' GUARD <<'PY' || true
import json, os, re, shlex, sys

HOME = os.path.expanduser("~")
LEGACY = [os.path.join(HOME, "github", "dotfiles"), os.path.join(HOME, "github", "nix-darwin")]
WRAPPERS = {"command", "exec", "nohup", "time", "nice", "caffeinate", "xargs", "env", "builtin"}
SHELLS = {"sh", "bash", "zsh", "dash", "ksh"}
SEPARATORS = {";", "&&", "||", "|", "&", "|&", "(", ")", "\n", ";;"}
WRITE_ANY_ARG = {"rm", "rmdir", "touch", "mkdir", "chmod", "chown", "chflags", "truncate", "tee", "unlink", "mv"}
WRITE_DEST_ARG = {"cp", "ln", "install", "rsync", "ditto"}
GIT_READ_ONLY = {"status", "log", "diff", "show", "ls-files", "rev-parse", "blame", "grep", "cat-file", "describe", "shortlog", "ls-tree", "config", "branch", "remote", "reflog"}
CONTENT_FIELDS = ("content", "new_string", "edits", "new_source", "old_string")

class Refuse(Exception):
    pass

class Ask(Exception):
    pass

def legacy(path, cwd):
    if not path:
        return False
    p = os.path.expanduser(os.path.expandvars(path))
    if not os.path.isabs(p):
        p = os.path.join(cwd, p)
    p = os.path.realpath(p)
    return any(p == root or p.startswith(root + os.sep) for root in LEGACY)

def strip_heredocs(text):
    """Remove heredoc bodies, returning (text, bodies fed to a shell)."""
    lines = text.split("\n")
    out, shell_bodies, i = [], [], 0
    while i < len(lines):
        line = lines[i]
        out.append(line)
        m = re.search(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1", line)
        if m:
            delim = m.group(2)
            body = []
            i += 1
            while i < len(lines) and lines[i].strip() != delim:
                body.append(lines[i])
                i += 1
            # The body is shell only when the command receiving it is a shell:
            # `bash <<EOF` runs it, `git commit -F - <<EOF` merely reads it.
            segment = re.split(r"&&|\|\||[;|&(]", line[: m.start()])[-1].split()
            words = unwrap(segment)
            if words and os.path.basename(words[0]) in SHELLS:
                shell_bodies.append("\n".join(body))
        i += 1
    return "\n".join(out), shell_bodies

def normalise(script):
    """Drop comments and turn unquoted newlines into `;`, quote-aware.

    shlex cannot be trusted with either. Its commenter starts a comment at a
    `#` in the middle of a word, so `nix build .#host && git push` loses the
    push; and a comment swallows the newline that separated the next command.
    Both failed open before this pass existed.
    """
    out, i, n, quote = [], 0, len(script), None
    while i < n:
        c = script[i]
        if quote == "'":
            out.append(c)
            if c == "'":
                quote = None
        elif quote == '"':
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(script[i + 1])
                i += 1
            elif c == '"':
                quote = None
        elif c == "\\" and i + 1 < n:
            if script[i + 1] == "\n":
                i += 1
            else:
                out.append(c)
                out.append(script[i + 1])
                i += 1
        elif c in "'\"":
            quote = c
            out.append(c)
        elif c == "#" and (not out or out[-1] in " \t\r\n;&|()"):
            while i < n and script[i] != "\n":
                i += 1
            continue
        elif c == "\n":
            out.append(" ; ")
        else:
            out.append(c)
        i += 1
    return "".join(out)

def tokenize(script):
    lex = shlex.shlex(normalise(script), posix=True, punctuation_chars=";&|()<>")
    lex.whitespace = " \t\r"
    lex.whitespace_split = True
    lex.commenters = ""
    try:
        return list(lex)
    except ValueError as e:
        raise Refuse("the shell command could not be parsed (%s)" % e)

def simple_commands(tokens):
    cmd = []
    for t in tokens:
        if t in SEPARATORS:
            if cmd:
                yield cmd
            cmd = []
        else:
            cmd.append(t)
    if cmd:
        yield cmd

def nested(token):
    """Command substitutions inside a word, analysed as shell."""
    found = re.findall(r"\$\(([^()]*)\)", token) + re.findall(r"`([^`]*)`", token)
    return found

def unwrap(argv):
    while argv:
        name = os.path.basename(argv[0])
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", argv[0]):
            argv = argv[1:]
        elif name in WRAPPERS:
            argv = argv[1:]
            while argv and (argv[0].startswith("-") or re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", argv[0])):
                argv = argv[1:]
        else:
            break
    return argv

def check_argv(argv, state):
    for t in argv:
        for inner in nested(t):
            check_shell(inner, state)
    argv = unwrap(argv)
    if not argv:
        return
    name = os.path.basename(argv[0])
    args = argv[1:]
    cwd = state["cwd"]

    if name in ("sudo", "doas"):
        raise Refuse("sudo is never run by an agent; hand the step to the owner for a real terminal (AGENTS.md)")
    if name in SHELLS and len(args) >= 2 and re.match(r"^-[a-z]*c[a-z]*$", args[0]):
        check_shell(args[1], state)
    if name == "eval":
        check_shell(" ".join(args), state)
    if name == "cd":
        target = args[0] if args else HOME
        target = os.path.expanduser(os.path.expandvars(target))
        state["cwd"] = os.path.realpath(target if os.path.isabs(target) else os.path.join(cwd, target))
        return
    if name == "darwin-rebuild" and any(a in ("switch", "activate") for a in args):
        raise Refuse("darwin-rebuild %s is the owner's manual step; agents are build-only (ADR 0003, ADR 0015)" % next(a for a in args if a in ("switch", "activate")))
    if name in ("activate", "activate-user") or (name == "home-manager" and "switch" in args):
        raise Refuse("activation scripts are never run by an agent (AGENTS.md)")
    if name == "nix" and len(args) >= 2 and args[0] == "flake" and args[1] == "update":
        raise Refuse("flake.lock moves only in dedicated commits; nix flake update is not run ad hoc (ADR 0011)")
    if name == "dot-link.sh" and legacy(argv[0], cwd):
        raise Refuse("the legacy repositories are read-only; their bin/dot-link.sh is never run (AGENTS.md)")
    if name in SHELLS and args and os.path.basename(args[0]) == "dot-link.sh" and legacy(args[0], cwd):
        raise Refuse("the legacy repositories are read-only; their bin/dot-link.sh is never run (AGENTS.md)")

    if name == "git":
        repo, rest = cwd, list(args)
        while rest and rest[0].startswith("-"):
            opt = rest.pop(0)
            if opt == "-C" and rest:
                d = os.path.expanduser(rest.pop(0))
                repo = os.path.realpath(d if os.path.isabs(d) else os.path.join(repo, d))
            elif opt in ("-c", "--git-dir", "--work-tree") and rest:
                rest.pop(0)
        sub = rest[0] if rest else ""
        if sub == "push":
            raise Refuse("git push is the owner's; agents never push (AGENTS.md, ADR 0008)")
        if legacy(repo, "/") and sub and sub not in GIT_READ_ONLY:
            raise Refuse("git %s would change a legacy repository, which is read-only (AGENTS.md)" % sub)
        if sub == "commit":
            state["ask"] = "git commit needs the owner's explicit instruction (AGENTS.md, ADR 0008)"
        return

    targets = []
    if name in WRITE_ANY_ARG:
        targets = [a for a in args if not a.startswith("-")]
    elif name in WRITE_DEST_ARG:
        operands = [a for a in args if not a.startswith("-")]
        targets = operands[-1:]
    elif name in ("sed", "perl") and any(re.match(r"^-[a-zA-Z]*i", a) for a in args):
        targets = [a for a in args if not a.startswith("-")][1:]
    for t in targets:
        if legacy(t, cwd):
            raise Refuse("%s would write into a legacy repository, which is read-only (AGENTS.md)" % name)

def check_shell(script, state):
    script, bodies = strip_heredocs(script)
    for body in bodies:
        check_shell(body, state)
    tokens = tokenize(script)
    for i, t in enumerate(tokens):
        if t in (">", ">>") and i + 1 < len(tokens) and legacy(tokens[i + 1], state["cwd"]):
            raise Refuse("output redirection into a legacy repository, which is read-only (AGENTS.md)")
    for argv in simple_commands(tokens):
        argv = [a for j, a in enumerate(argv) if a not in (">", ">>", "<", "<<") and not (j > 0 and argv[j - 1] in (">", ">>", "<"))]
        check_argv(argv, state)

def patch_paths(text):
    return re.findall(r"^\*\*\* (?:Add|Update|Delete) File: (.+)$|^\*\*\* Move to: (.+)$", text, re.M)

def decide(data):
    if not isinstance(data, dict):
        raise Refuse("the hook input is not a JSON object")
    ti = data.get("tool_input")
    if not isinstance(ti, dict):
        ti = {}
    # cursor-agent sends cwd as an empty string and names the workspace instead.
    roots = data.get("workspace_roots")
    cwd = data.get("cwd") or (roots[0] if isinstance(roots, list) and roots and isinstance(roots[0], str) else "") or os.getcwd()
    state = {"cwd": os.path.realpath(cwd), "ask": None}

    command = ti.get("command", data.get("command"))
    # Codex's apply_patch carries the patch text in `command`. It is checked as
    # a patch below; parsing it as shell would refuse any patch with a quote.
    if isinstance(command, str) and command.lstrip().startswith("*** Begin Patch"):
        command = None
    if command is not None:
        if isinstance(command, list) and all(isinstance(c, str) for c in command):
            check_argv(command, state)
        elif isinstance(command, str):
            check_shell(command, state)
        else:
            raise Refuse("the command field has an unexpected shape")

    path = ti.get("file_path", ti.get("notebook_path", ti.get("path")))
    writes = any(k in ti for k in CONTENT_FIELDS)
    if path is not None and writes:
        if not isinstance(path, str):
            raise Refuse("the file path has an unexpected shape")
        if legacy(path, state["cwd"]):
            raise Refuse("writing into a legacy repository, which is read-only (AGENTS.md)")
    for value in ti.values():
        if isinstance(value, str) and "*** Begin Patch" in value:
            for groups in patch_paths(value):
                p = groups[0] or groups[1]
                if legacy(p.strip(), state["cwd"]):
                    raise Refuse("a patch that writes into a legacy repository, which is read-only (AGENTS.md)")

    # Codex rejects "ask"; its input is the one carrying turn_id without
    # cursor_version. Claude Code and cursor-agent both honour it.
    codex = "turn_id" in data and "cursor_version" not in data
    if state["ask"] and not codex:
        raise Ask(state["ask"])

def emit(decision, reason):
    reason = "agent-guard: " + reason
    print(json.dumps({
        "hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": decision, "permissionDecisionReason": reason},
    }))

try:
    with open(sys.argv[1], encoding="utf-8") as f:
        raw = f.read()
    try:
        data = json.loads(raw)
    except ValueError:
        raise Refuse("the hook input is not valid JSON")
    decide(data)
except Refuse as r:
    emit("deny", str(r))
except Ask as a:
    emit("ask", str(a))
except Exception as e:
    emit("deny", "internal error (%s); refusing rather than failing open" % type(e).__name__)
PY

trap - ERR
python3 -c "$GUARD" "$input" || deny "the checker exited abnormally; refusing rather than failing open"
exit 0
