#!/usr/bin/env zsh

# Configure environment variables without any plugins

# Set the zsh variables
ZDOTDIR="${HOME}/.config/zsh"
export HISTFILE=$ZDOTDIR/history
export HISTORY_IGNORE=''
export HISTSIZE=1000000000
export SAVEHIST=1000000000
export LANG=en_US.UTF-8
export ARCHFLAGS="-arch x86_64" # Compilation flags

export fpath=($fpath \
  $ZDOTDIR/complete \
  $ZDOTDIR/functions \
)

# PATH environment variable configuration
# PATH is managed by Home Manager via home.sessionPath (modules/home/base.nix)
# For project-specific PATH modifications, use .envrc files with direnv

# To add the stack compiler bin to your PATH, run: add_stack_compiler_bin_to_path
add_stack_compiler_bin_to_path() {
  local stack_bin
  stack_bin=$(stack path --compiler-bin --silent 2>/dev/null)
  if [[ -n "$stack_bin" && ":$PATH:" != *":$stack_bin:"* ]]; then
    PATH="$stack_bin:$PATH"
  fi
}
#
# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

echo "read .zprofile from ${HOME}/.config/zsh"
#######################
# Mark as loaded file #
#######################
alias zsh_profile_loaded='echo "zsh_profile_loaded"'


