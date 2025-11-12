# DemoTape Vim Syntax

Syntax highlighting for DemoTape (`.tape`) files in Vim/Neovim.

## Installation

### Using a Plugin Manager

#### vim-plug

Add to your `.vimrc` or `init.vim`:

```vim
Plug 'fnando/demotape', {'rtp': 'editors/vim'}
```

#### Vundle

```vim
Plugin 'fnando/demotape', {'rtp': 'editors/vim'}
```

#### Pathogen

```bash
cd ~/.vim/bundle
git clone https://github.com/fnando/demotape.git
ln -s ~/.vim/bundle/demotape/editors/vim ~/.vim/bundle/demotape-vim
```

### Manual Installation

Copy the files to your Vim directory:

```bash
# For Vim
cp -r editors/vim/* ~/.vim/

# For Neovim
cp -r editors/vim/* ~/.config/nvim/
```

## Features

- Syntax highlighting for all DemoTape commands
- Support for key combinations and special keys
- String literals (single, double, and triple-quoted multiline)
- Duration values with time units
- Regular expressions
- Comments
- Set command options

## Usage

Once installed, any file with a `.tape` extension will automatically use DemoTape syntax highlighting.

You can also manually set the filetype:

```vim
:set filetype=demotape
```

## Configuration

You can customize the colors by overriding the highlight groups in your `.vimrc`:

```vim
" Example: Make commands bold
hi demotapeCommand gui=bold cterm=bold

" Example: Custom color for strings
hi demotapeString guifg=#98c379 ctermfg=114
```

Available highlight groups:

- `demotapeComment` - Comments
- `demotapeCommand` - Commands (Type, Sleep, etc.)
- `demotapeKey` - Special keys (Enter, Tab, etc.)
- `demotapeModifier` - Modifier keys (Ctrl, Alt, etc.)
- `demotapeOperator` - Operators (+ and @)
- `demotapeOption` - Set command options
- `demotapeString` - String literals
- `demotapeStringMulti` - Multiline strings
- `demotapeEscape` - Escape sequences
- `demotapeRegex` - Regular expressions
- `demotapeNumber` - Integer numbers
- `demotapeFloat` - Floating point numbers
- `demotapeDuration` - Duration values
- `demotapeBoolean` - Boolean values
- `demotapeSeparator` - Separators (commas)
