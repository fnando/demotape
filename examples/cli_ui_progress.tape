Include "examples/meta/cli.tape"

Type "CLI::UI::Progress.progress { |bar| 100.times { sleep 0.02; bar.tick } }"
Sleep .5
Enter
Sleep 5
