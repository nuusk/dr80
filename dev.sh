#!/usr/bin/bash

SESSION=dr80
CONFIG="$HOME/code/dr80/.tmux"

tmux has-session -t "$SESSION" 2>/dev/null
if [ $? -ne 0 ]; then
  tmux source-file "$CONFIG"
fi

kitty tmux attach -t "$SESSION"
