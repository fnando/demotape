Set variable_typing 0.3
Require "bat"
Require "vim"

Pause
Send "rm -rf examples/script.rb && rm -rf \"examples/.script.rb*\"\n"
WaitUntil /^$/
Clear
Resume

Sleep 1s
Type "vim -u NONE -i NONE examples/script.rb"
Enter
Sleep 1s

# Enable syntax highlighting
Shift+Colon
Type "syntax on"
Enter

# Insert mode
Type "i"

Type """
# This is a sample Ruby script
puts "Hello, World!"

"""

Esc
Sleep 3s
Shift+Colon
Type "x"
Enter
Sleep 1s
Type "bat examples/script.rb"
Enter
Sleep 2s
Type "ruby examples/script.rb"
Enter
Sleep 3s
