Require "ll"
Set width 1000
Set height 700
Set padding 20
Set font_size 20

Send 'echo "This theme is $THEME"\n'
Sleep 1ms
WaitUntil /This theme/
Run "ll"
Sleep 5s
Screenshot
