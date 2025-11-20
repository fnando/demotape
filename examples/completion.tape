Pause
Send "autoload -Uz compinit && compinit\n"
Clear
Resume

Run@10s "bat lib/demo_tape/cli.rb --line-range=168:181"

Type "q"
Run@1s "clear"

Run "demotape completion --shell zsh > ~/.config/zsh-completions/_demotape"
Run "source ~/.config/zsh-completions/_demotape"
Run@1s "clear"

Type "demotape "
Sleep 1s
Tab
Sleep 1s
Tab 2
Sleep 500ms
Space
Sleep 500ms
Tab
Sleep 500ms
Space
Tab
Sleep 500ms
Type "z"
Sleep 500ms
Tab
Screenshot
Sleep 3s
Ctrl+U
Sleep 1s
