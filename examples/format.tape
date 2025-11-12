Set typing_speed 20ms
Pause
Send "gem install cli-ui\n"
Send "irb --noautocomplete\n"
Send "require 'cli/ui'\n"
Send "CLI::UI::StdoutRouter.enable\n"
WaitUntil /true/
Clear
Sleep 1
Resume

Type 'puts CLI::UI.fmt "{{red:Red}} {{green:Green}}"'
Sleep .5
Enter
Sleep 5
