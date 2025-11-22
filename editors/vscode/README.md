# Demo Tape VSCode Extension

Syntax highlighting for [Demo Tape](https://github.com/fnando/demotape)
(`.tape`) files in Visual Studio Code.

## Installation

### Marketplace

1. Open Visual Studio Code
2. Go to the Extensions view (`Ctrl+Shift+X` or `Cmd+Shift+X` on macOS)
3. Search for
   [DemoTape](https://marketplace.visualstudio.com/items?itemName=fnando.demotape)

### Manual Installation

Copy this directory to your VSCode extensions folder:

- **Windows**: `%USERPROFILE%\.vscode\extensions\demotape`
- **macOS/Linux**: `~/.vscode/extensions/demotape`

Then reload VSCode.

## Features

- Syntax highlighting for all DemoTape commands
- Support for key combinations and special keys
- String literals (single, double, and triple-quoted multiline)
- Duration values with time units
- Comments
- Set command options

## Development

To test during development:

1. Open this folder in VSCode
2. Press `F5` to launch Extension Development Host
3. Open any `.tape` file to see syntax highlighting
