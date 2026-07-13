#!/usr/bin/env zsh

# zsh-abbr abbreviation definitions
# This file defines all shell abbreviations that will be loaded on startup
# Using --quieter flag to suppress output messages

# Git abbreviations
abbr add --quieter g='git'
abbr add --quieter gs='git status'
abbr add --quieter ga='git add'
abbr add --quieter gaa='git add --all'
abbr add --quieter gc='git commit'
abbr add --quieter gcm='git commit -m'
abbr add --quieter gca='git commit --amend'
abbr add --quieter gp='git push'
abbr add --quieter gpl='git pull'
abbr add --quieter gd='git diff'
abbr add --quieter gds='git diff --staged'
abbr add --quieter gco='git checkout'
abbr add --quieter gcb='git checkout -b'
abbr add --quieter gb='git branch'
abbr add --quieter gba='git branch -a'
abbr add --quieter gl='git log --oneline --graph --decorate'
abbr add --quieter gst='git stash'
abbr add --quieter gstp='git stash pop'

# Directory navigation
abbr add --quieter --force ..='cd ..'
abbr add --quieter --force ...='cd ../..'
abbr add --quieter --force ....='cd ../../..'

# Common commands
abbr add --quieter ll='ls -lah'
abbr add --quieter la='ls -A'
abbr add --quieter l='ls -CF'

# Docker abbreviations
abbr add --quieter d='docker'
abbr add --quieter --force dc='docker-compose'
abbr add --quieter dps='docker ps'
abbr add --quieter dpsa='docker ps -a'
abbr add --quieter di='docker images'
abbr add --quieter dex='docker exec -it'
abbr add --quieter dlog='docker logs -f'

# Kubernetes abbreviations
abbr add --quieter k='kubectl'
abbr add --quieter kg='kubectl get'
abbr add --quieter kgp='kubectl get pods'
abbr add --quieter kgs='kubectl get services'
abbr add --quieter kd='kubectl describe'
abbr add --quieter kl='kubectl logs'
abbr add --quieter klf='kubectl logs -f'
abbr add --quieter kx='kubectl exec -it'
abbr add --quieter ka='kubectl apply -f'
abbr add --quieter kdel='kubectl delete'

# Tmux abbreviations
abbr add --quieter ta='tmux attach'
abbr add --quieter tat='tmux attach -t'
abbr add --quieter tl='tmux list-sessions'
abbr add --quieter tn='tmux new-session'
abbr add --quieter tnt='tmux new-session -s'

# Neovim abbreviations
abbr add --quieter v='vim'

# System utilities
abbr add --quieter reload='source ~/.config/zsh/.zshrc'

# Add your custom abbreviations below
# abbr add --quieter myabbr='my command'
