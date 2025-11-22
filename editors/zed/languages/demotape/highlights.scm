; Comments
(comment) @comment

; Command keywords - using string literals
"Type" @keyword
"TypeFile" @keyword
"Run" @keyword
"WaitUntil" @keyword
"Set" @keyword
"Output" @keyword
"Copy" @keyword
"Send" @keyword
"Include" @keyword
"Screenshot" @keyword
"Wait" @keyword
"Sleep" @keyword
"Require" @keyword
"Group" @keyword
"do" @keyword
"end" @keyword

; Command keywords - simple commands (just the literal)
(paste_command) @keyword
(pause_command) @keyword
(resume_command) @keyword
(clear_command) @keyword


; Group blocks
(group_block
  name: (identifier) @function)
(group_invocation
  group: (identifier) @function)

; Keys
(special_key) @constant
(modifier_key) @constant
(letter_key) @constant

; Operators
"@" @operator
"+" @operator
"," @punctuation.delimiter

; Strings
(string) @string
(escape_sequence) @string.escape
(unquoted_string) @string

; Regex
(regex) @string.regex

; Numbers and durations
(number) @number
(duration) @number

; Booleans
(boolean) @boolean

; Set options
(set_command
  option: (set_option) @constant)

; Identifiers
(identifier) @variable

; Force highlight for problematic words with higher priority
((set_option) @constant
  (#match? @constant "^(height|margin)$")
  (#set! "priority" 200))
