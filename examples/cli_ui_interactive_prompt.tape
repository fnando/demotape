Include "examples/meta/cli.tape"

Run "CLI::UI.ask('What do you use?', options: %w[javascript go ruby python])"

Down@.5 3
Sleep 1
Up@.5 2
Sleep 1
Down@.5
Sleep 1
Enter
WaitUntil@3s /You chose: ruby/
Sleep 3
