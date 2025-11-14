#!/usr/bin/env bash

SESSION=dr80
CONFIG="$HOME/code/dr80/.tmux"

# Create session if missing
tmux has-session -t "$SESSION" 2>/dev/null || tmux source-file "$CONFIG"

# Launch kitty normally and attach from a shell
kitty sh -c "tmux attach -t '$SESSION'"
