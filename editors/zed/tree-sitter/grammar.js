module.exports = grammar({
  name: 'demotape',

  extras: $ => [
    /\s/,
  ],

  rules: {
    source_file: $ => repeat(choice(
      $.comment,
      $.group_block,
      $.command,
      $.newline,
    )),

    newline: $ => /\r?\n/,

    comment: $ => /#.*/,

    // Group blocks
    group_block: $ => seq(
      'Group',
      field('name', $.identifier),
      'do',
      repeat(choice(
        $.comment,
        $.command,
        $.newline,
      )),
      'end'
    ),

    identifier: $ => /[a-z_][a-z0-9_]*/,

    // Commands
    command: $ => choice(
      $.type_command,
      $.run_command,
      $.wait_until_command,
      $.type_file_command,
      $.set_command,
      $.output_command,
      $.copy_command,
      $.paste_command,
      $.send_command,
      $.include_command,
      $.screenshot_command,
      $.wait_command,
      $.sleep_command,
      $.require_command,
      $.pause_command,
      $.resume_command,
      $.clear_command,
      $.key_command,
      $.group_invocation,
    ),

    // Group invocation
    group_invocation: $ => seq(
      field('group', $.identifier),
    ),

    // Type command
    type_command: $ => seq(
      'Type',
      optional($.duration_modifier),
      field('text', $.string),
    ),

    // TypeFile command
    type_file_command: $ => seq(
      'TypeFile',
      optional($.duration_modifier),
      field('path', $.string),
    ),

    // Run command
    run_command: $ => seq(
      'Run',
      optional($.duration_modifier),
      field('command', $.string),
    ),

    // WaitUntil command
    wait_until_command: $ => seq(
      'WaitUntil',
      optional($.duration_modifier),
      field('pattern', $.regex),
    ),

    // Set command
    set_command: $ => seq(
      'Set',
      field('option', $.set_option),
      field('value', choice(
        $.string,
        $.number,
        $.duration,
        $.boolean,
        $.unquoted_string,
      )),
      optional(seq(',', field('value', choice($.number, $.duration)))),
      optional(seq(',', field('value', choice($.number, $.duration)))),
      optional(seq(',', field('value', choice($.number, $.duration)))),
    ),

    set_option: $ => /[a-z_]+(\.[a-z_]+)?/,

    // Output command
    output_command: $ => seq(
      'Output',
      field('path', $.string),
    ),

    // Copy command
    copy_command: $ => seq(
      'Copy',
      field('text', $.string),
    ),

    // Paste command
    paste_command: $ => 'Paste',

    // Send command
    send_command: $ => seq(
      'Send',
      field('text', $.string),
    ),

    // Include command
    include_command: $ => seq(
      'Include',
      field('path', $.string),
    ),

    // Screenshot command
    screenshot_command: $ => seq(
      'Screenshot',
      optional(field('path', $.string)),
    ),

    // Wait/Sleep commands
    wait_command: $ => seq(
      'Wait',
      field('duration', choice($.number, $.duration)),
    ),

    sleep_command: $ => seq(
      'Sleep',
      field('duration', choice($.number, $.duration)),
    ),

    // Require command
    require_command: $ => seq(
      'Require',
      field('command', choice($.string, $.identifier)),
    ),

    // Control commands
    pause_command: $ => 'Pause',
    resume_command: $ => 'Resume',
    clear_command: $ => 'Clear',

    // Key commands
    key_command: $ => seq(
      field('key', $.key_combination),
      optional($.duration_modifier),
      optional(field('count', $.number)),
    ),

    key_combination: $ => choice(
      $.special_key,
      $.modifier_key,
      seq(
        choice($.modifier_key, $.letter_key),
        repeat1(seq('+', choice($.modifier_key, $.special_key, $.letter_key))),
      ),
    ),

    special_key: $ => choice(
      'Enter', 'Return', 'Tab', 'Backspace', 'Delete', 'Escape', 'Esc',
      'Space', 'Up', 'Down', 'Left', 'Right', 'Home', 'End',
      'PageUp', 'PageDown', 'Insert', 'Cancel', 'Help',
      'Semicolon', 'Colon', 'Equals', 'Slash', 'BackSlash',
      /Numpad[0-9]/, 'Multiply', 'Add', 'Separator', 'Subtract', 'Decimal', 'Divide',
      /F([1-9]|1[0-2])/,
    ),

    modifier_key: $ => choice(
      'Ctrl', 'Control', 'Alt', 'Option', 'Shift', 'Meta', 'Command'
    ),

    letter_key: $ => /[A-Za-z0-9]/,

    // Modifiers
    duration_modifier: $ => seq('@', field('duration', choice($.duration, $.number))),

    // Literals
    string: $ => choice(
      seq('"""', field('content', /([^"]|"[^"]|""[^"])*?/), '"""'),
      seq('"', field('content', repeat(choice(/[^"\\]+/, $.escape_sequence))), '"'),
      seq("'", field('content', repeat(choice(/[^'\\]+/, $.escape_sequence))), "'"),
    ),

    escape_sequence: $ => token(seq(
      '\\',
      choice(
        /[ntr\\"']/,
        /u[0-9a-fA-F]{4}/,
        /U[0-9a-fA-F]{8}/,
      )
    )),

    unquoted_string: $ => /[a-zA-Z_]\w*/,

    regex: $ => /\/([^\/\\]|\\.)*\//,

    duration: $ => token(seq(
      /\d+(\.\d+)?/,
      choice('ms', 's', 'm', 'h'),
    )),

    number: $ => /\d+(\.\d+)?/,

    boolean: $ => choice('true', 'false'),
  }
});
