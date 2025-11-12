Type "date"
Enter
Type "ruby -e '5.times { puts %[line #{_1 + 1} - #{Time.now}]; sleep 1 }'"
Enter
WaitUntil@11s /line 5/
Type "date"
Enter
Wait 2s
