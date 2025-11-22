# DemoTape Syntax Highlighting Test File
# This file tests all DemoTape language features

# =============================================================================
# Output Configuration
# =============================================================================

Output "examples/syntax.mp4"
Output "examples/syntax.gif"
Screenshot "examples/syntax.png"

# =============================================================================
# Set Commands - Display Settings
# =============================================================================

Set width 1280
Set height 720
Set font_family "Monaco"
Set font_size 16
Set line_height 1.5

# =============================================================================
# Set Commands - Theme and Colors
# =============================================================================

Set theme "default"
Set theme.background "#1e1e1e"
Set theme.foreground "#d4d4d4"
Set theme.cursor "#00ff00"
Set theme.selection "#264f78"

# =============================================================================
# Set Commands - Padding and Margin
# =============================================================================

Set padding 20
Set padding 20, 40
Set margin 60
Set margin_fill "#6b50ff"

# =============================================================================
# Set Commands - Cursor Settings
# =============================================================================

Set cursor_blink true
Set cursor_blink false
Set cursor_style "block"
Set cursor_style "bar"
Set cursor_width 2

# =============================================================================
# Set Commands - Animation Settings
# =============================================================================

Set typing_speed 50ms
Set fps 60
Set loop true
Set loop_delay 5s
Set variable_typing true
Set run_enter_delay 300ms
Set run_sleep 1s

# =============================================================================
# Set Commands - Shell
# =============================================================================

Set shell bash
Set shell zsh

# =============================================================================
# Wait and Sleep Commands
# =============================================================================

Sleep 1
Sleep 2s
Sleep 500ms
Sleep 1.5s
Sleep 2m
Sleep 1h
Wait 1
Wait 2s
Wait 500ms

# =============================================================================
# Type Commands - Basic
# =============================================================================

Type "Hello, World!"
Type 'Single quotes work too'
Type "Escape sequences: \n\t\"\\"
Type "Unicode: \u0041 \U0001F600"

# =============================================================================
# Type Commands - Multiline Strings
# =============================================================================

Type """
This is a multiline string.
Line breaks are preserved.
Multiple lines of text.
"""

# =============================================================================
# Type Commands - Speed Modifiers
# =============================================================================

Type@100ms "Typing with 100ms per character"
Type@50ms "Faster typing"
Type@500ms "Very slow typing"
Type@1s "Ultra slow typing"

# =============================================================================
# TypeFile Command
# =============================================================================

TypeFile "path/to/file.txt"
TypeFile@50ms "path/to/another.txt"

# =============================================================================
# Run Command
# =============================================================================

Run "echo 'Hello'"
Run "ls -la"
Run "npm install"
Run@5s "long-running-command"
Run@10s "very-long-command"

# =============================================================================
# WaitUntil Command
# =============================================================================

WaitUntil /ready/
WaitUntil /complete/
WaitUntil@5s /pattern/
WaitUntil@30s /done/
WaitUntil /error|failed/

# =============================================================================
# Special Keys - Individual
# =============================================================================

Enter
Return
Tab
Backspace
Delete
Escape
Esc
Space
Up
Down
Left
Right
Home
End
PageUp
PageDown
Insert
Cancel
Help

# =============================================================================
# Special Keys - With Counts
# =============================================================================

Enter 3
Space 5
Backspace 10
Tab 2
Delete 4

# =============================================================================
# Function Keys
# =============================================================================

F1
F2
F3
F4
F5
F6
F7
F8
F9
F10
F11
F12

# =============================================================================
# Modifier Keys
# =============================================================================

Ctrl
Control
Alt
Option
Shift
Meta
Command

# =============================================================================
# Key Combinations - Simple
# =============================================================================

Ctrl+C
Alt+F
Alt+1
Shift+Enter
Command+Space
Meta+Tab

# =============================================================================
# Key Combinations - Multiple Modifiers
# =============================================================================

Ctrl+Shift+T
Ctrl+Alt+Delete
Command+Shift+P
Alt+Shift+F

# =============================================================================
# Key Combinations - With Letters and Numbers
# =============================================================================

Ctrl+A
Ctrl+C
Ctrl+V
Ctrl+Z
Alt+1
Alt+2
Shift+A

# =============================================================================
# Key Combinations - With Counts
# =============================================================================

Ctrl+C 2
Enter@500ms 3
Backspace@100ms 10

# =============================================================================
# Numpad Keys
# =============================================================================

Numpad0
Numpad1
Numpad5
Numpad9
Multiply
Add
Separator
Subtract
Decimal
Divide

# =============================================================================
# Special Characters Keys
# =============================================================================

Semicolon
Colon
Equals
Slash
BackSlash

# =============================================================================
# Clipboard Commands
# =============================================================================

Copy "text to copy"
Paste
Copy "another string"

# =============================================================================
# Send Command
# =============================================================================

Send "raw text without typing effect"
Send 'more raw text'

# =============================================================================
# Control Commands
# =============================================================================

Pause
Resume
Clear

# =============================================================================
# Include Command
# =============================================================================

Include "other.tape"
Include "examples/setup.tape"

# =============================================================================
# Require Command
# =============================================================================

Require "git"
Require "node"
Require "ll"

# =============================================================================
# Group Blocks
# =============================================================================

Group setup do
  Clear
  Type "# Setting up environment"
  Enter
  Sleep 500ms
end

Group cleanup do
  Type "echo 'Cleaning up...'"
  Enter
  Wait 1s
end

# =============================================================================
# Group Invocations
# =============================================================================

setup
cleanup
setup

# =============================================================================
# Complex Example - Real Usage
# =============================================================================

Clear
Sleep 1s

Type "# Demo Tape Syntax Test"
Enter 2

Type "echo 'Testing all features'"
Enter
Sleep 500ms

Type "ls -la"
Enter
WaitUntil@2s /total/

Sleep 1s
Type "git status"
Enter
Sleep 1s

Ctrl+C
Sleep 500ms

Type "# Complex key combinations"
Enter
Ctrl+Shift+T
Alt+F4
Command+Space

Sleep 1s
Type "# Numbers and durations"
Enter
Type "Duration: 500ms, 2s, 1.5m, 1h"
Enter

Sleep 2s
Screenshot

# =============================================================================
# Edge Cases
# =============================================================================

Type ""
Type ''
Type "Quoted \"strings\" with escapes"
Type 'Single \'quotes\' too'

# Test all boolean values
Set cursor_blink true
Set cursor_blink false

# Test all number formats
Set width 1920
Set height 1080
Set font_size 14
Set typing_speed 0.05s
Set padding 10, 20, 30, 40

# =============================================================================
# Comments Throughout
# =============================================================================

# Comment at the start
Type "text" # Inline comments are not supported in DemoTape
# Comment at the end
