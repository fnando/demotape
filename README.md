# Demo Tape

[![Tests](https://github.com/fnando/demotape/workflows/ruby-tests/badge.svg)](https://github.com/fnando/demotape)
[![Gem](https://img.shields.io/gem/v/demotape.svg)](https://rubygems.org/gems/demotape)
[![Gem](https://img.shields.io/gem/dt/demotape.svg)](https://rubygems.org/gems/demotape)
[![MIT License](https://img.shields.io/:License-MIT-blue.svg)](https://tldrlegal.com/license/mit-license)

![Demo Tape in action!](https://github.com/fnando/demotape/raw/main/examples/fastfetch.gif)

Record terminal sessions from your CLI tools

## Dependencies

- [ffmpeg](https://ffmpeg.org/) (for video encoding)
- [ttyd](https://github.com/tsl0922/ttyd) (for terminal recording)

## Installation

```bash
gem install demotape
```

Or add the following line to your project's Gemfile:

```ruby
gem "demotape"
```

### Editor Integration

Demo Tape has extensions for several editors to provide syntax highlighting and
snippets.

- Sublime Text: https://github.com/fnando/sublime-demotape/
- VSCode: https://marketplace.visualstudio.com/items?itemName=fnando.demotape
- vim: https://github.com/fnando/demotape/blob/main/editors/vim/README.md

### Shell Completion

Demo Tape supports shell completion for Bash, Zsh, Fish, and PowerShell. To set
up completion for your shell:

**Bash:**

```bash
demotape completion --shell=bash > /usr/local/etc/bash_completion.d/demotape
```

Or add this to your `~/.bashrc`:

```bash
source <(demotape completion --shell=bash)
```

**Zsh:**

Add this to your `~/.zshrc`:

```zsh
source <(demotape completion --shell=zsh)
```

Or generate the completion script to a file in your `$fpath`:

```zsh
demotape completion --shell=zsh > /usr/local/share/zsh/site-functions/_demotape
```

**Fish:**

```fish
demotape completion --shell=fish > ~/.config/fish/completions/demotape.fish
```

**PowerShell:**

Add this to your PowerShell profile:

```powershell
demotape completion --shell=powershell | Out-String | Invoke-Expression
```

## Usage

Run a Demo Tape script:

```console
$ demotape run path/to/script.tape
        info  Running <stdin>
        info  Using zsh
     command  Type 'echo "it works with stdin too"'
     command  Enter
     command  Sleep 5
      output  Generating examples/stdin.mp4
        info  Finished in 11.92s
```

Run from stdin:

```console
$ echo "Type 'echo \"it works with stdin too\"'\nEnter\nSleep 5" | \
  exe/demotape run --overwrite --output-path examples/stdin.mp4
        info  Running <stdin>
        info  Using zsh
     command  Type 'echo "it works with stdin too"'
     command  Enter
     command  Sleep 5
      output  Generating examples/stdin.mp4
        info  Finished in 11.92s
```

> [!TIP]
>
> Notice that when using `--working-dir`, all path references will be relative
> to the working directory, including `--output-path`.

### Output formats

- When exporting videos, you can choose between `.mp4`, `.webm` or `.avi`.
  Choose `.avi`/`.mp4` if you need a lossless intermediate video to be processed
  in a pipeline.

### Examples

The [`examples/`](https://github.com/fnando/demotape/tree/main/examples) folder
contains several Demo Tape scripts showcasing different features. There you'll
also find the generated output files (videos, GIFs, and screenshots).

## Demo Tape Syntax

Demo Tape scripts (`.tape` files) consist of a series of commands, one per line.
Each command performs an action in the terminal recording, such as typing text,
pressing keys, waiting, or configuring the recording session.

### Basic Syntax

Commands follow this general structure:

```text
CommandName [arguments] [options]
```

Comments start with `#` and must be on their own line:

```demotape
# This is a comment
# Comments must be on separate lines, not inline
Type "Hello"
```

Empty lines are ignored and can be used for readability.

### Commands

#### Text and Typing

**Type** - Types text into the terminal

```demotape
Type "text"
Type@500ms "slow typing"
Type@2s "very slow"
Type@10ms "fast typing"
```

Strings must be quoted (double or single quotes). Speed modifiers (e.g.,
`@500ms`) control how fast each character is typed. Supported time units: `ms`
(milliseconds), `s` (seconds), `m` (minutes), `h` (hours).

**Multiline strings** - Use triple quotes for multiline text:

```demotape
Type """
echo "Type 'echo \"multiline support\"'"
echo "Line breaks are preserved"
"""
```

Content between `"""` markers preserves line breaks and spacing. This is useful
for typing multiple commands or complex text that spans several lines.

**TypeFile** - Reads file and types its text into the terminal

```demotape
TypeFile "path/to/file"
```

**Run** - Type a command, wait, press Enter, and wait for output

```demotape
Run "clear"
Run "ls -la"
Run@5s "npm install"
```

The `Run` command is a convenience that combines typing text, waiting briefly,
pressing Enter, and waiting for the command to complete. It's equivalent to:

```demotape
Type "command"
Sleep 300ms
Enter
Sleep 1s
```

You can customize the timing behavior:

```demotape
Set run_enter_delay 300ms  # Time to wait before pressing Enter (default: 300ms)
Set run_sleep 1s            # Time to wait after pressing Enter (default: 1s)
```

The `@` modifier overrides the post-Enter sleep duration:

```demotape
Run@5s "long-running-command"  # Waits 5s after Enter instead of 1s
```

#### Keys and Key Combinations

- **Special keys:** `Backspace`, `Delete`, `End`, `Enter`, `Escape`, `Home`,
  `Insert`, `PageDown` `PageUp`, `Space`, `Tab`
- **Arrow keys:** `Up`, `Down`, `Left`, `Right`
- **Function keys:** `F1`-`F12`
- **Modifier keys:** `Alt`, `Command` `Control`/`Ctrl`, `Meta`, `Option`,
  `Shift`

##### Key Combinations

You can combine modifier keys with special keys using `+`:

```demotape
Ctrl+C
Alt+F
Shift+Enter
Ctrl+Shift+T
Command+Space
Ctrl+Alt+Delete
```

##### Key Counts

You can specify how many times to press a key by adding a number after the key.

```demotape
Enter 3
Space 5
Backspace 10
Ctrl+C 2
```

#### Timing and Waiting

**Wait**/**Sleep** - Pause for a specific duration

```demotape
Wait 1
Wait 2s
Wait 500ms
Wait 1.5s
Wait 2m
Wait 1h

Sleep 1
Sleep 2s
Sleep 500ms
Sleep 1.5s
Sleep 2m
Sleep 1h
```

When no time unit is specified, seconds are assumed.

**WaitUntil** - Wait for output matching a pattern

```demotape
WaitUntil /pattern/
WaitUntil@5s /ready/
WaitUntil@10s /complete/
```

The pattern is a regular expression. The command waits until the terminal output
matches the pattern or the timeout is reached.

**WaitUntilDone** - Wait for output matching `/::done::`. This is just a
shortcut for `WaitUntil /::done::/`.

```demotape
WaitUntilDone
WaitUntilDone@5s
```

#### Clipboard

**Copy** - Copy text to clipboard

```demotape
Copy "text to copy"
```

**Paste** - Paste from clipboard

```demotape
Paste
```

#### Recording Control

**Output** - Set output file path(s)

```demotape
Output "recording.mp4"
Output "demo.gif"
Output "demo.webm"
Output "demo.mov"
```

You can specify multiple Output commands to generate multiple formats:

```demotape
Output "demo.gif"
Output "demo.mp4"
Output "demo.webm"
```

**Screenshot** - Take a screenshot

```demotape
Screenshot
Screenshot "screenshot.png"
```

Notes:

- when called without a path, if there's exactly one screenshot, then the name
  will be inferred from the output path (e.g. `video.png`).
- when called without a path, if more than one screenshot is taken, than the
  filename will be inferred from the output path plus a screenshot count (e.g.
  `video-01.png`).
- if more than one output path was specified, then a screenshot will be saved in
  each of those paths.

**Pause** - Pause recording

```demotape
Pause
```

**Resume** - Resume recording

```demotape
Resume
```

#### Screen Control

**Clear** - Clear the terminal screen

```demotape
Clear
```

**Send** - Send raw text to terminal, with no typing effect

```demotape
Send "raw text"
```

#### Configuration

`Set` commands configure the recording session. These are typically placed at
the beginning of the file, but don't have to; they're executed before executing
other commands. Last definitions will replace previous ones.

**Display Dimensions**

```demotape
Set width 1280
Set height 720
```

**Font Settings**

```demotape
Set font_family "Menlo"
Set font_size 16
Set line_height 1.5
```

**Appearance**

```demotape
Set theme "default"
Set theme "default_light"
Set theme "themes/some_theme.json"
```

You can also override specific theme colors using dot notation:

```demotape
Set theme.background "#222222"
Set theme.foreground "#ffffff"
Set theme.cursor "#00ff00"
Set theme.selection "#444444"
```

**Spacing**

```demotape
Set padding 20
Set padding 20, 40
Set padding 10, 20, 30
Set padding 10, 20, 30, 40
Set margin 60
Set margin 20, 40
Set margin 10, 20, 30
Set margin 10, 20, 30, 40
Set margin_fill "#6b50ff"
Set margin_fill "examples/background.png"
```

Padding can be specified with 1-4 values: uniform (all sides), vertical and
horizontal, top/horizontal/bottom, or top/right/bottom/left.

Margin works the same way as padding but adds outer space around the terminal
window. MarginFill sets the background color (hex color) or image (file path)
for the margin area.

**Cursor**

```demotape
Set cursor_blink true
Set cursor_blink false
Set cursor_style "block"
Set cursor_style "bar"
Set cursor_style "underline"
Set cursor_width 2
```

**Typing Speed**

```demotape
Set typing_speed 50ms
Set typing_speed 0.1s
```

**GIF Animation Loops**

```demotape
Set loop true
Set loop false
Set loop_delay 5s
```

**Shell**

```demotape
Set shell bash
Set shell zsh
Set shell fish
```

#### Script Organization

**Include** - Include another tape file

```demotape
Include "other.tape"
Include "examples/setup.tape"
```

**Require** - Require a command to be available

```demotape
Require "git"
Require "ll"
```

**Group** - Define reusable command groups

Groups allow you to define a set of commands that can be called multiple times:

```demotape
Group hello do
  Run "echo 'Hello, World!'"
  Run "echo 'Goodbye, World!'"
end

hello
Run "echo 'In between groups'"
hello
```

In this example, the `hello` group is defined with two commands and then called
twice. Groups help organize and reuse common command sequences in your scripts.

### Data Types

#### Strings

Strings must be quoted with double or single quotes:

```demotape
Type "Hello, World!"
Type 'Hello, World!'
```

Both double-quoted and single-quoted strings support escape sequences.

Escape sequences in quoted strings:

```demotape
Type "Line 1\nLine 2"
Type "Tab\there"
Type "Quote: \"text\""
Type "Backslash: \\"
Type "Unicode: \u0041"
Type "Emoji: \U0001F600"
```

Supported escape sequences: `\n` (newline), `\t` (tab), `\"` (quote), `\\`
(backslash), `\u` (4-digit Unicode), `\U` (8-digit Unicode).

#### Numbers

Numbers can be integers or decimals:

```demotape
Sleep 1
Sleep 1.5s
Set width 1920
Set typing_speed 0.05s
```

#### Durations

Durations consist of a number followed by a time unit:

```demotape
500ms
2s
1.5s
5m
1h
```

Valid time units: `ms`, `s`, `m`, `h`

#### Regular Expressions

Regular expressions are enclosed in forward slashes:

```demotape
WaitUntil /complete/
WaitUntil /error|failed/
WaitUntil /line \d+/
```

#### Booleans

Boolean values for Set commands:

```demotape
Set loop true
Set loop false
```

### Modifiers

#### Duration Modifier (@)

Controls duration for various commands. For Type commands and key presses, it
sets the typing speed. For WaitUntil commands, it sets the timeout:

```demotape
# Typing speed
Type@100ms "text"
Enter@500ms
Ctrl+C@1s
Backspace@50ms 5

# Timeout for WaitUntil
WaitUntil@5s /pattern/
WaitUntil@30s /ready/
```

### Complete Example

```demotape
# Configure the recording
Output "demo.mp4"
Output "demo.gif"

Set width 1280
Set height 720
Set font_family "Monaco"
Set font_size 14
Set theme "default"
Set padding 20

# Start recording
Sleep 1

Type "echo 'Hello, Demo Tape!'"
Enter
Sleep 500ms

Type "ls -la"
Enter
Sleep 1s

# Use key combinations
Ctrl+C
Sleep 500ms

# Type slowly for emphasis
Type@200ms "This is slow typing"
Enter
Sleep 2s

# Wait for command completion
Type "npm install"
Enter
WaitUntil@60s /packages installed/

# Take a screenshot
Screenshot "final.png"

Sleep 1s
```

### Valid Commands Reference

- **Typing**: `Type`, `TypeFile`, `Run`
- **Special Keys**: `Enter`, `Space`, `Tab`, `Backspace`, `Escape`, `Delete`,
  `Insert`, `Home`, `End`, `PageUp`, `PageDown`, `Up`, `Down`, `Left`, `Right`,
  `F1-F12`
- **Modifiers**: `Shift`, `Control`/`Ctrl`, `Alt`/`Option`, `Meta`/`Command`
- **Timing**: `Sleep`, `Wait`, `WaitUntil`
- **Clipboard**: `Copy`, `Paste`
- **Recording**: `Output`, `Screenshot`, `Pause`, `Resume`
- **Screen**: `Clear`, `Send`
- **Configuration**: `Set`
- **Organization**: `Include`, `Require`, `Group`

### Notes

- Commands are case-sensitive (e.g., `Type`, not `type`)
- Each command must be on its own line
- Trailing whitespace is allowed but not required
- Comments start with `#` and must be on their own line (inline comments not
  supported)
- Empty lines are ignored

## Acknowledgements

This project is heavily inspired by [vhs](https://github.com/charmbracelet/vhs)
and was created to provide similar functionality in Ruby, while solving some
quirks and adding some extra features.

> [!WARNING]
>
> The syntax is not fully compatible with vhs. Although some commands are
> similar, there are many differences. Please refer to the Demo Tape syntax
> documentation above.

## Maintainer

- [Nando Vieira](https://github.com/fnando)

## Contributors

- https://github.com/fnando/demotape/contributors

## Contributing

For more details about how to contribute, please read
https://github.com/fnando/demotape/blob/main/CONTRIBUTING.md.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT). A copy of the license can be
found at https://github.com/fnando/demotape/blob/main/LICENSE.md.

## Code of Conduct

Everyone interacting in the Demo Tape project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/fnando/demotape/blob/main/CODE_OF_CONDUCT.md).
