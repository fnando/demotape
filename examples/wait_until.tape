Type "date"
Enter
Type "ruby -e '5.times { puts %[line #{_1 + 1} - #{Time.now}]; sleep 1 }'"
Enter
WaitUntil@11s /^\$$/
Sleep 500ms
Type "date"
Enter
Wait 2s
