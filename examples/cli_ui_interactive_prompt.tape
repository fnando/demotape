Include "examples/meta/cli.tape"

Type "CLI::UI.ask('What do you use?', options: %w(javascript go ruby python))"
Sleep .5
Enter
Sleep 1

Down@.5 3
Sleep 1
Up@.5 2
Sleep 1
Down@.5
Sleep 1
Enter

Sleep 3
