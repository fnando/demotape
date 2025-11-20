Set typing_speed 20ms
Pause
Send "gem install cli-ui\n"
WaitUntil /gem installed/
Send "irb --noautocomplete\n"
WaitUntil /:001>/
Send "require 'cli/ui'\n"
Send "CLI::UI::StdoutRouter.enable\n"
WaitUntil /true/
Clear
Sleep 1
Resume
