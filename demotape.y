class DemoTape::Parser
rule
  tape: commands { result = val[0] }
      | metadata { result = [] }
      | /* empty */ { result = [] }

  metadata: COMMENT NEWLINE { result = nil }
          | metadata COMMENT NEWLINE { result = nil }
          | NEWLINE { result = nil }
          | metadata NEWLINE { result = nil }

  commands: leading_space command trailing_space NEWLINE { result = [val[1]] }
          | commands leading_space command trailing_space NEWLINE { result = val[0] << val[2] }
          | leading_space block trailing_space NEWLINE { result = [val[1]] }
          | commands leading_space block trailing_space NEWLINE { result = val[0] << val[2] }
          | metadata leading_space command trailing_space NEWLINE { result = [val[2]] }
          | metadata leading_space block trailing_space NEWLINE { result = [val[2]] }
          | commands COMMENT NEWLINE { result = val[0] }
          | commands NEWLINE { result = val[0] }

  leading_space: LEADING_SPACE { result = nil }
               | /* empty */ { result = nil }

  trailing_space: TRAILING_SPACE { result = nil }
                | SPACE { result = nil }
                | /* empty */ { result = nil }

  optional_space: SPACE { result = val[0] }
                | LEADING_SPACE { result = val[0] }
                | TRAILING_SPACE { result = val[0] }
                | /* empty */ { result = nil }

  block: block_start block_commands leading_space END {
           cmd = val[0]
           cmd.children.replace(val[1])
           result = cmd.prepare!
         }

  block_start: IDENTIFIER SPACE IDENTIFIER SPACE DO trailing_space NEWLINE {
           # When this rule is being reduced:
           # val[0] = first IDENTIFIER value
           # val[1] = first SPACE value
           # val[2] = second IDENTIFIER value
           # val[3] = second SPACE value
           # val[4] = DO value
           # val[5] = trailing_space (nil or SPACE value)
           # val[6] = NEWLINE value
           
           # @token_index is AFTER consuming NEWLINE
           # We need to count backwards to find each token's position
           
           # trailing_space can be 0 or 1 token
           trailing_consumed = val[5].nil? ? 0 : 1
           
           # Working backwards from @token_index:
           # @token_index points to NEXT token (after NEWLINE)
           # @token_index - 1 = NEWLINE
           # @token_index - 2 = trailing_space (if present) or DO (if not)
           # So: @token_index - 1 - trailing_consumed = DO
           #     @token_index - 2 - trailing_consumed = SPACE before DO
           #     @token_index - 3 - trailing_consumed = second IDENTIFIER
           #     @token_index - 4 - trailing_consumed = first SPACE
           #     @token_index - 5 - trailing_consumed = first IDENTIFIER
           
           identifier_index = @token_index - 6 - trailing_consumed
           space1_index = @token_index - 5 - trailing_consumed
           name_index = @token_index - 4 - trailing_consumed
           space2_index = @token_index - 3 - trailing_consumed
           do_index = @token_index - 2 - trailing_consumed
           
           @command_start_index = identifier_index
           
           tokens = [
             make_token(:identifier, val[0], identifier_index),
             make_token(:space, val[1], space1_index),
             make_token(:identifier, val[2], name_index),
             make_token(:space, val[3], space2_index),
             make_token(:keyword, val[4], do_index)
           ]

           cmd = DemoTape::Command.new(val[0], val[2], children: [])
           cmd.tokens = tokens
           result = attach_location(cmd)
         }

  block_commands: leading_space command trailing_space NEWLINE { result = [val[1]] }
                | block_commands leading_space command trailing_space NEWLINE { result = val[0] << val[2] }
                | leading_space block trailing_space NEWLINE { result = [val[1]] }
                | block_commands leading_space block trailing_space NEWLINE { result = val[0] << val[2] }
                | COMMENT NEWLINE { result = [] }
                | block_commands COMMENT NEWLINE { result = val[0] }

  trailing_space: SPACE { result = nil }
                | /* empty */ { result = nil }

  command: IDENTIFIER SPACE PLUS {
             space_index = @token_index - 2
             line_info = @lexer.line_map[space_index] || {}
             error_msg = "Unexpected token \"SPACE\" at #{@file}:#{line_info[:line]}:#{line_info[:column]}:\n"
             error_msg += "  #{line_info[:content]}\n"
             error_msg += "  #{' ' * (line_info[:column] - 1)}^"
             raise DemoTape::ParseError, error_msg
           }
         | key_combo SPACE NUMBER {
             @command_start_index = @last_key_index
             keys = val[0][:keys]
             key_tokens = val[0][:tokens]
             command_name = keys.shift

             tokens = key_tokens + [
               make_token(:space, val[1], @token_index - 2),
               make_token(:number, val[2], @token_index - 1)
             ]

             cmd = DemoTape::Command.new(command_name, "", keys:, count: val[2])
             cmd.tokens = tokens
             result = attach_location(cmd).prepare!
           }
         | key_combo {
             @command_start_index = @last_key_index
             keys = val[0][:keys]
             key_tokens = val[0][:tokens]
             command_name = keys.shift

             cmd = DemoTape::Command.new(command_name, "", keys:)
             cmd.tokens = key_tokens
             result = attach_location(cmd).prepare!
           }
         | IDENTIFIER SPACE NUMBER {
             @command_start_index = @token_index - 4
             duration_index = @token_index - 2
             space_index = @token_index - 3

             tokens = [
               make_token(:identifier, val[0], @token_index - 4),
               make_token(:space, val[1], space_index),
               make_token(:number, val[2], @token_index - 2)
             ]

             # Duration commands (Sleep, Wait) treat bare numbers as seconds
             # Key commands treat numbers as repeat counts
             if ["Sleep", "Wait"].include?(val[0])
               cmd = DemoTape::Command.new(val[0], "#{val[2]}s")
               cmd.tokens = tokens
               result = attach_location(cmd, duration_index: duration_index).prepare!
             else
               cmd = DemoTape::Command.new(val[0], "", count: val[2])
               cmd.tokens = tokens
               result = attach_location(cmd).prepare!
             end
           }
         | IDENTIFIER AT duration SPACE string {
             @command_start_index = @token_index - 6
             duration_index = @token_index - 3  # TIME_UNIT position

             tokens = [
               make_token(:identifier, val[0], @token_index - 6),
               make_token(:operator, "@", @token_index - 5),
               make_token(:duration, val[2], @token_index - 4),
               make_token(:space, val[3], @token_index - 2),
               make_token(:string, val[4], @token_index - 1)
             ]

             cmd = DemoTape::Command.new(val[0], val[4], duration: val[2])
             cmd.tokens = tokens
             result = attach_location(cmd, duration_index:).prepare!
           }
         | IDENTIFIER AT duration SPACE NUMBER {
             @command_start_index = @token_index - 6
             duration_index = @token_index - 3  # TIME_UNIT position

             tokens = [
               make_token(:identifier, val[0], @token_index - 6),
               make_token(:operator, "@", @token_index - 5),
               make_token(:duration, val[2], @token_index - 4),
               make_token(:space, val[3], @token_index - 2),
               make_token(:number, val[4], @token_index - 1)
             ]

             cmd = DemoTape::Command.new(val[0], "", duration: val[2], count: val[4])
             cmd.tokens = tokens
             result = attach_location(cmd, duration_index:).prepare!
           }
         | IDENTIFIER AT NUMBER SPACE NUMBER {
             @command_start_index = @token_index - 5
             duration_index = @token_index - 3

             tokens = [
               make_token(:identifier, val[0], @token_index - 5),
               make_token(:operator, "@", @token_index - 4),
               make_token(:number, val[2], @token_index - 3),
               make_token(:space, val[3], @token_index - 2),
               make_token(:number, val[4], @token_index - 1)
             ]

             cmd = DemoTape::Command.new(val[0], "", duration: "#{val[2]}s", count: val[4])
             cmd.tokens = tokens
             result = attach_location(cmd, duration_index:).prepare!
           }
         | IDENTIFIER AT NUMBER SPACE string {
             @command_start_index = @token_index - 5
             duration_index = @token_index - 3

             tokens = [
               make_token(:identifier, val[0], @token_index - 5),
               make_token(:operator, "@", @token_index - 4),
               make_token(:number, val[2], @token_index - 3),
               make_token(:space, val[3], @token_index - 2),
               make_token(:string, val[4], @token_index - 1)
             ]

             cmd = DemoTape::Command.new(val[0], val[4], duration: "#{val[2]}s")
             cmd.tokens = tokens
             result = attach_location(cmd, duration_index:).prepare!
           }
         | IDENTIFIER AT NUMBER {
             @command_start_index = @token_index - 3
             duration_index = @token_index - 1

             tokens = [
               make_token(:identifier, val[0], @token_index - 3),
               make_token(:operator, "@", @token_index - 2),
               make_token(:number, val[2], @token_index - 1)
             ]

             cmd = DemoTape::Command.new(val[0], "", duration: "#{val[2]}s")
             cmd.tokens = tokens
             result = attach_location(cmd, duration_index:).prepare!
           }
         | IDENTIFIER AT duration {
             @command_start_index = @token_index - 4
             duration_index = @token_index - 1  # TIME_UNIT position

             tokens = [
               make_token(:identifier, val[0], @token_index - 4),
               make_token(:operator, "@", @token_index - 3),
               make_token(:duration, val[2], @token_index - 2)
             ]

             cmd = DemoTape::Command.new(val[0], "", duration: val[2])
             cmd.tokens = tokens
             result = attach_location(cmd, duration_index:).prepare!
           }
         | IDENTIFIER AT duration SPACE REGEX {
             @command_start_index = @token_index - 6
             duration_index = @token_index - 3  # TIME_UNIT position
             regex_index = @token_index - 1

             begin
               Regexp.new(val[4])
             rescue RegexpError => e
               line_info = @lexer.line_map[regex_index] || {}
               error_msg = "Invalid regex: #{e.message} at #{@file}:#{line_info[:line]}:#{line_info[:column]}:\n"
               error_msg += "  #{line_info[:content]}\n"
               error_msg += "  #{' ' * (line_info[:column] - 1)}^"
               raise DemoTape::ParseError, error_msg
             end

             tokens = [
               make_token(:identifier, val[0], @token_index - 6),
               make_token(:operator, "@", @token_index - 5),
               make_token(:duration, val[2], @token_index - 4),
               make_token(:space, val[3], @token_index - 2),
               make_token(:regex, val[4], regex_index)
             ]

             cmd = DemoTape::Command.new(val[0], val[4], duration: val[2])
             cmd.tokens = tokens
             result = attach_location(cmd, duration_index:).prepare!
           }
         | IDENTIFIER SPACE REGEX {
             @command_start_index = @token_index - 3
             regex_index = @token_index - 1

             begin
               Regexp.new(val[2])
             rescue RegexpError => e
               line_info = @lexer.line_map[regex_index] || {}
               error_msg = "Invalid regex: #{e.message} at #{@file}:#{line_info[:line]}:#{line_info[:column]}:\n"
               error_msg += "  #{line_info[:content]}\n"
               error_msg += "  #{' ' * (line_info[:column] - 1)}^"
               raise DemoTape::ParseError, error_msg
             end

             tokens = [
               make_token(:identifier, val[0], @token_index - 3),
               make_token(:space, val[1], @token_index - 2),
               make_token(:regex, val[2], regex_index)
             ]

             cmd = DemoTape::Command.new(val[0], val[2])
             cmd.tokens = tokens
             result = attach_location(cmd).prepare!
           }
         | IDENTIFIER SPACE IDENTIFIER SPACE NUMBER optional_space COMMA optional_space NUMBER optional_space COMMA optional_space NUMBER optional_space COMMA optional_space NUMBER {
             @command_start_index = @token_index - 11

             # Build tokens array - for optional spaces, just create simple tokens
             tokens = []
             tokens << make_token(:identifier, val[0], @token_index - 11)
             tokens << make_token(:space, val[1], @token_index - 10)
             tokens << make_token(:identifier, val[2], @token_index - 9)
             tokens << make_token(:space, val[3], @token_index - 8)
             tokens << make_token(:number, val[4], @token_index - 7)
             tokens << DemoTape::Token::Space.new(val[5]) if val[5]
             tokens << DemoTape::Token::Operator.new(",")
             tokens << DemoTape::Token::Space.new(val[7]) if val[7]
             tokens << make_token(:number, val[8], @token_index - 5)
             tokens << DemoTape::Token::Space.new(val[9]) if val[9]
             tokens << DemoTape::Token::Operator.new(",")
             tokens << DemoTape::Token::Space.new(val[11]) if val[11]
             tokens << make_token(:number, val[12], @token_index - 3)
             tokens << DemoTape::Token::Space.new(val[13]) if val[13]
             tokens << DemoTape::Token::Operator.new(",")
             tokens << DemoTape::Token::Space.new(val[15]) if val[15]
             tokens << make_token(:number, val[16], @token_index - 1)

             cmd = DemoTape::Command.new(val[0], [val[4], val[8], val[12], val[16]], option: val[2])
             cmd.tokens = tokens
             result = attach_location(cmd).prepare!
           }
         | IDENTIFIER SPACE IDENTIFIER SPACE NUMBER optional_space COMMA optional_space NUMBER optional_space COMMA optional_space NUMBER {
             @command_start_index = @token_index - 9

             tokens = []
             tokens << make_token(:identifier, val[0], @token_index - 9)
             tokens << make_token(:space, val[1], @token_index - 8)
             tokens << make_token(:identifier, val[2], @token_index - 7)
             tokens << make_token(:space, val[3], @token_index - 6)
             tokens << make_token(:number, val[4], @token_index - 5)
             tokens << DemoTape::Token::Space.new(val[5]) if val[5]
             tokens << DemoTape::Token::Operator.new(",")
             tokens << DemoTape::Token::Space.new(val[7]) if val[7]
             tokens << make_token(:number, val[8], @token_index - 3)
             tokens << DemoTape::Token::Space.new(val[9]) if val[9]
             tokens << DemoTape::Token::Operator.new(",")
             tokens << DemoTape::Token::Space.new(val[11]) if val[11]
             tokens << make_token(:number, val[12], @token_index - 1)

             cmd = DemoTape::Command.new(val[0], [val[4], val[8], val[12]], option: val[2])
             cmd.tokens = tokens
             result = attach_location(cmd).prepare!
           }
         | IDENTIFIER SPACE IDENTIFIER SPACE NUMBER optional_space COMMA optional_space NUMBER {
             @command_start_index = @token_index - 7

             tokens = []
             tokens << make_token(:identifier, val[0], @token_index - 7)
             tokens << make_token(:space, val[1], @token_index - 6)
             tokens << make_token(:identifier, val[2], @token_index - 5)
             tokens << make_token(:space, val[3], @token_index - 4)
             tokens << make_token(:number, val[4], @token_index - 3)
             tokens << DemoTape::Token::Space.new(val[5]) if val[5]
             tokens << DemoTape::Token::Operator.new(",")
             tokens << DemoTape::Token::Space.new(val[7]) if val[7]
             tokens << make_token(:number, val[8], @token_index - 1)

             cmd = DemoTape::Command.new(val[0], [val[4], val[8]], option: val[2])
             cmd.tokens = tokens
             result = attach_location(cmd).prepare!
           }
         | IDENTIFIER SPACE IDENTIFIER SPACE duration {
             @command_start_index = @token_index - 6

             tokens = [
               make_token(:identifier, val[0], @token_index - 6),
               make_token(:space, val[1], @token_index - 5),
               make_token(:identifier, val[2], @token_index - 4),
               make_token(:space, val[3], @token_index - 3),
               make_token(:duration, val[4], @token_index - 2)
             ]

             cmd = DemoTape::Command.new(val[0], val[4], option: val[2])
             cmd.tokens = tokens
             result = attach_location(cmd).prepare!
           }
         | IDENTIFIER SPACE IDENTIFIER SPACE NUMBER {
             @command_start_index = @token_index - 5

             tokens = [
               make_token(:identifier, val[0], @token_index - 5),
               make_token(:space, val[1], @token_index - 4),
               make_token(:identifier, val[2], @token_index - 3),
               make_token(:space, val[3], @token_index - 2),
               make_token(:number, val[4], @token_index - 1)
             ]

             cmd = DemoTape::Command.new(val[0], val[4].to_s, option: val[2])
             cmd.tokens = tokens
             result = attach_location(cmd).prepare!
           }
         | IDENTIFIER SPACE IDENTIFIER SPACE IDENTIFIER {
             @command_start_index = @token_index - 5

             tokens = [
               make_token(:identifier, val[0], @token_index - 5),
               make_token(:space, val[1], @token_index - 4),
               make_token(:identifier, val[2], @token_index - 3),
               make_token(:space, val[3], @token_index - 2),
               make_token(:identifier, val[4], @token_index - 1)
             ]

             cmd = DemoTape::Command.new(val[0], val[4], option: val[2])
             cmd.tokens = tokens
             result = attach_location(cmd).prepare!
           }
         | IDENTIFIER SPACE IDENTIFIER SPACE string {
             @command_start_index = @token_index - 5

             tokens = [
               make_token(:identifier, val[0], @token_index - 5),
               make_token(:space, val[1], @token_index - 4),
               make_token(:identifier, val[2], @token_index - 3),
               make_token(:space, val[3], @token_index - 2),
               make_token(:string, val[4], @token_index - 1)
             ]

             cmd = DemoTape::Command.new(val[0], val[4], option: val[2])
             cmd.tokens = tokens
             result = attach_location(cmd).prepare!
           }
         | IDENTIFIER SPACE string {
             @command_start_index = @token_index - 3

             tokens = [
               make_token(:identifier, val[0], @token_index - 3),
               make_token(:space, val[1], @token_index - 2),
               make_token(:string, val[2], @token_index - 1)
             ]

             cmd = DemoTape::Command.new(val[0], val[2])
             cmd.tokens = tokens
             result = attach_location(cmd).prepare!
           }
         | IDENTIFIER SPACE duration {
             @command_start_index = @token_index - 4
             duration_index = @token_index - 1  # TIME_UNIT position

             tokens = [
               make_token(:identifier, val[0], @token_index - 4),
               make_token(:space, val[1], @token_index - 3),
               make_token(:duration, val[2], @token_index - 2)
             ]

             cmd = DemoTape::Command.new(val[0], val[2])
             cmd.tokens = tokens
             result = attach_location(cmd, duration_index: duration_index).prepare!
           }
         | IDENTIFIER {
             @command_start_index = @token_index - 1

             tokens = [make_token(:identifier, val[0], @token_index - 1)]

             # This could be a group invocation, mark it as such
             cmd = DemoTape::Command.new(val[0], "", group_invocation: true)
             cmd.tokens = tokens
             result = attach_location(cmd).prepare!
           }

  key_combo: IDENTIFIER PLUS IDENTIFIER {
               @last_key_index = @token_index - 1

               tokens = [
                 make_token(:identifier, val[0], @token_index - 3),
                 make_token(:operator, "+", @token_index - 2),
                 make_token(:identifier, val[2], @token_index - 1)
               ]

               result = { keys: [val[0], val[2]], tokens: tokens }
             }
           | IDENTIFIER PLUS NUMBER {
               @last_key_index = @token_index - 1

               tokens = [
                 make_token(:identifier, val[0], @token_index - 3),
                 make_token(:operator, "+", @token_index - 2),
                 make_token(:number, val[2], @token_index - 1)
               ]

               result = { keys: [val[0], val[2].to_s], tokens: tokens }
             }
           | key_combo PLUS IDENTIFIER {
               @last_key_index = @token_index - 1

               tokens = val[0][:tokens] + [
                 make_token(:operator, "+", @token_index - 2),
                 make_token(:identifier, val[2], @token_index - 1)
               ]

               result = { keys: val[0][:keys] << val[2], tokens: tokens }
             }
           | key_combo PLUS NUMBER {
               @last_key_index = @token_index - 1

               tokens = val[0][:tokens] + [
                 make_token(:operator, "+", @token_index - 2),
                 make_token(:number, val[2], @token_index - 1)
               ]

               result = { keys: val[0][:keys] << val[2].to_s, tokens: tokens }
             }

  string: STRING { result = val[0] }
        | WORD { result = val[0] }

  duration: NUMBER TIME_UNIT { result = "#{val[0]}#{val[1]}" }

end

---- header

---- inner
  def parse(str, file: "<unknown>")
    @file = file
    @lexer = DemoTape::Lexer.new
    @tokens = @lexer.tokenize(str)
    @token_index = 0
    do_parse
  end

  def next_token
    token = @tokens.shift
    @current_token_index = @token_index
    @token_index += 1
    token
  end

  def make_token(type, value, index)
    line_info = @lexer.line_map[index] || {}
    token_class = case type
                  when :identifier then Token::Identifier
                  when :string then Token::String
                  when :number then Token::Number
                  when :duration then Token::Duration
                  when :regex then Token::Regex
                  when :time_unit then Token::TimeUnit
                  when :operator then Token::Operator
                  when :space then Token::Space
                  when :leading_space then Token::LeadingSpace
                  when :trailing_space then Token::TrailingSpace
                  when :keyword then Token::Keyword
                  else Token::Base
                  end

    token_class.new(
      value,
      line: line_info[:line],
      column: line_info[:column],
      raw: line_info[:raw]
    )
  end

  def attach_location(command, duration_index: nil)
    line_info = @lexer.line_map[@command_start_index] || {}
    command.line = line_info[:line]
    command.column = line_info[:column]
    command.line_content = line_info[:content]
    command.file = @file

    # Attach duration/speed/timeout specific columns if provided
    if duration_index
      duration_info = @lexer.line_map[duration_index] || {}
      command.duration_column = duration_info[:column]
    end

    command
  end

  def on_error(token_id, token_value, value_stack)
    # Get line metadata from the lexer's line map
    line_info = @lexer.line_map[@current_token_index] || {}
    line_num = line_info[:line] || "?"
    col_num = line_info[:column] || 1
    line_content = line_info[:content] || ""

    token_name = token_to_str(token_id) || token_id.to_s

    error_msg = "Unexpected token #{token_name.inspect} at #{@file}:#{line_num}:#{col_num}:\n"
    error_msg += "  #{line_content}\n"
    error_msg += "  #{' ' * (col_num - 1)}^"

    raise DemoTape::ParseError, error_msg
  end

---- footer
