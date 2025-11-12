Include "examples/meta/cli.tape"

Type "CLI::UI::Frame.open('Frame 1') do"
Enter
Type "  CLI::UI::Frame.open('Frame 2') { puts 'inside frame 2' }"
Enter
Type "  puts 'inside frame 1'"
Enter
Type "end"

Sleep 1

Enter

Sleep 3
