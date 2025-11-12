Require "tmux"

Pause
  Send "tmux -f /dev/null -L test new-session -- bash"
  Enter
  Send "tmux split-window -d -h -- bash && \\"
  Enter
  Send "tmux set status && \\"
  Enter
  Send 'tmux setw pane-border-style "fg=0" && \\'
  Enter
  Send 'tmux setw pane-active-border-style "fg=0"'
  Enter
  Sleep 0.5
  Ctrl+L
  Sleep 1
Resume

Type "Window 1"
Sleep 1

# tmux bind to switch to next pane
Ctrl+B
Type "o"

Sleep 1
Type "Window 2"
Sleep 1
