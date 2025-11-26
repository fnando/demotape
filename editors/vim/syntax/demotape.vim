" Vim syntax file
" Language: Demo Tape
" Maintainer: Nando Vieira
" Latest Revision: 2024-11-12

if exists("b:current_syntax")
  finish
endif

" Comments
syn match demotapeComment "#.*$"

" Commands
syn keyword demotapeCommand Type TypeFile WaitUntil WaitUntilDone Run Set Output Copy Paste Send Include Screenshot
syn keyword demotapeCommand Wait Sleep Require Pause Resume Clear nextgroup=demotapeString,demotapeDuration,demotapeNumber skipwhite

" Group blocks
syn keyword demotapeCommand Group nextgroup=demotapeGroupName skipwhite
syn match demotapeGroupName "\<[a-z_][a-z0-9_]*\>" contained nextgroup=demotapeGroupDo skipwhite
syn keyword demotapeGroupDo do contained
syn keyword demotapeGroupEnd end

" Group invocations (lowercase identifiers on their own line)
syn match demotapeGroupInvocation "^\s*\zs[a-z_][a-z0-9_]*\ze\s*$"

" Special keys
syn keyword demotapeKey Enter Return Tab Backspace Delete Escape Esc Space
syn keyword demotapeKey Up Down Left Right Home End PageUp PageDown Insert
syn keyword demotapeKey Cancel Help Pause Semicolon Colon Equals Slash BackSlash
syn keyword demotapeKey Multiply Add Separator Subtract Decimal Divide
syn match demotapeKey "\<Numpad[0-9]\>"
syn match demotapeKey "\<F\([1-9]\|1[0-2]\)\>"

" Modifiers
syn keyword demotapeModifier Ctrl Control Alt Option Shift Meta Command Cmd

" Key combination operator
syn match demotapeOperator "+"
syn match demotapeOperator "@"

" Set options
syn keyword demotapeOption border_radius shell theme width height font_size font_family
syn keyword demotapeOption line_height cursor_blink cursor_width cursor_style letter_spacing
syn keyword demotapeOption padding margin margin_fill fps typing_speed loop loop_delay variable_typing
syn keyword demotapeOption run_enter_delay run_sleep
syn match demotapeOption "\<\(border_radius\|shell\|theme\|width\|height\|font_size\|font_family\|line_height\|cursor_blink\|cursor_width\|cursor_style\|letter_spacing\|padding\|margin\|margin_fill\|fps\|typing_speed\|loop_delay\|loop\|variable_typing\|run_enter_delay\|run_sleep\)\.\w\+\>"

" Strings
syn region demotapeString start=+"+ skip=+\\\\\|\\"+ end=+"+ contains=demotapeEscape
syn region demotapeString start=+'+ skip=+\\\\\|\\'+ end=+'+ contains=demotapeEscape
syn region demotapeStringMulti start=+"""+ end=+"""+ contains=demotapeEscape

" String escapes
syn match demotapeEscape "\\[ntr\\'\"]" contained
syn match demotapeEscape "\\u[0-9a-fA-F]\{4\}" contained
syn match demotapeEscape "\\U[0-9a-fA-F]\{8\}" contained

" Regular expressions
syn region demotapeRegex start=+/+ skip=+\\\\\|\\\/+ end=+/+

" Numbers
syn match demotapeNumber "\<\d\+\>"
syn match demotapeFloat "\<\d\+\.\d\+\>"

" Duration with units
syn match demotapeDuration "\<\d\+\(\.\d\+\)\?\(ms\|s\|m\|h\)\>"

" Booleans
syn keyword demotapeBoolean true false

" Separators
syn match demotapeSeparator ","

" Highlight groups
hi def link demotapeComment Comment
hi def link demotapeCommand Keyword
hi def link demotapeGroupName Function
hi def link demotapeGroupDo Keyword
hi def link demotapeGroupEnd Keyword
hi def link demotapeGroupInvocation Function
hi def link demotapeKey Function
hi def link demotapeModifier Special
hi def link demotapeOperator Operator
hi def link demotapeOption Identifier
hi def link demotapeString String
hi def link demotapeStringMulti String
hi def link demotapeEscape SpecialChar
hi def link demotapeRegex String
hi def link demotapeNumber Number
hi def link demotapeFloat Float
hi def link demotapeDuration Number
hi def link demotapeBoolean Boolean
hi def link demotapeSeparator Delimiter

let b:current_syntax = "demotape"
