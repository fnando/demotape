Set variable_typing 0.3
Require "vim"

Sleep 1s
Type "vim -u NONE -i NONE"
Enter
Sleep 1s

# Enable syntax highlighting
Shift+Colon
Type "syntax on"
Enter

# Enable syntax highlighting
Shift+Colon
Type "source editors/vim/syntax/demotape.vim"
Enter

# Insert mode
Type "i"

TypeFile "examples/type_file.tape"
Sleep 5s
