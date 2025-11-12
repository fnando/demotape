Require "ll"
Set width 800
Set height 600
Set padding 20
Set font_size 20

Send 'echo "This theme is $THEME"\n'
Sleep 1ms
WaitUntil /This theme/
Send "ll\n"
Sleep 1ms
WaitUntil /test\//
Screenshot
