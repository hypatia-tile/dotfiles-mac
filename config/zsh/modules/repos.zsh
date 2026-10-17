#!/usr/bin/env zsh

# Record a visit to a ghq repository on every change of directory, however
# it happened, for the ordering in `repos pick` and the age in `repos clean`
# (config/bin/repos, #239). `repos visit` decides whether the directory is
# in a ghq repository and skips a repeat of the last line, so moving between
# subdirectories of one repository records nothing. `command`, because the
# executable is what is meant even where a function or alias of that name
# exists.
_repos_visit() {
  (( $+commands[repos] )) && command repos visit "$PWD"
  return 0
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _repos_visit

# chpwd does not run for the directory a shell starts in, which is where a
# new terminal pane opens.
_repos_visit
