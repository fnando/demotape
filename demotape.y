class DemoTape::Parser

# Precedence rules to resolve shift/reduce conflicts
# When we see LEADING_SPACE and END is in lookahead, reduce group_body instead of shifting
prechigh
  nonassoc END
  left LEADING_SPACE
preclow

rule
  # Document is a flat list - mix of tokens and command contexts
  document: lines { result = val[0].flatten.compact }
          | /* empty */ { result = [] }

  lines: line { result = val[0] }
       | lines line { result = val[0] + val[1] }

  # A line can be a comment, newline, group, or command
  line: COMMENT NEWLINE {
          result = [
            make_token(:comment, val[0], index_for_value(val[0])),
            make_token(:newline, val[1], index_for_value(val[1]))
          ]
        }
      | LEADING_SPACE COMMENT NEWLINE {
          result = [
            make_token(:leading_space, val[0], index_for_value(val[0])),
            make_token(:comment, val[1], index_for_value(val[1])),
            make_token(:newline, val[2], index_for_value(val[2]))
          ]
        }
      | NEWLINE { result = [make_token(:newline, val[0], index_for_value(val[0]))] }
      | group { result = [val[0]] }
      | line_tokens NEWLINE {
          tokens, start_idx = val[0]
          result = [
            { type: :command, tokens: tokens, line: line_for_token_at(start_idx), column: column_for_token_at(start_idx) },
            make_token(:newline, val[1], index_for_value(val[1]))
          ]
        }
      | LEADING_SPACE line_tokens NEWLINE {
          idx_lead = index_for_value(val[0])
          tokens, _ = val[1]
          result = [
            { type: :command, tokens: [make_token(:leading_space, val[0], idx_lead)] + tokens, line: line_for_token_at(idx_lead), column: column_for_token_at(idx_lead) },
            make_token(:newline, val[2], index_for_value(val[2]))
          ]
        }

  # Group block: tokens ending with 'do', body, then 'end'
  group: line_tokens DO NEWLINE group_body END NEWLINE {
           tokens, start_idx = val[0]
           idx_do = index_for_value(val[1])
           idx_nl = index_for_value(val[2])
           result = {
             type: :group,
             tokens: tokens + [make_token(:keyword, val[1], idx_do)],
             children: [make_token(:newline, val[2], idx_nl)] + val[3],
             line: line_for_token_at(start_idx),
             column: column_for_token_at(start_idx)
           }
         }
       | line_tokens DO NEWLINE group_body LEADING_SPACE END NEWLINE {
           tokens, start_idx = val[0]
           idx_do = index_for_value(val[1])
           idx_nl = index_for_value(val[2])
           # Discard the LEADING_SPACE before END (val[4])
           result = {
             type: :group,
             tokens: tokens + [make_token(:keyword, val[1], idx_do)],
             children: [make_token(:newline, val[2], idx_nl)] + val[3],
             line: line_for_token_at(start_idx),
             column: column_for_token_at(start_idx)
           }
         }
       | LEADING_SPACE line_tokens DO NEWLINE group_body END NEWLINE {
           idx_lead = index_for_value(val[0])
           tokens, _ = val[1]
           idx_do = index_for_value(val[2])
           idx_nl = index_for_value(val[3])
           result = {
             type: :group,
             tokens: [make_token(:leading_space, val[0], idx_lead)] + tokens + [make_token(:keyword, val[2], idx_do)],
             children: [make_token(:newline, val[3], idx_nl)] + val[4],
             line: line_for_token_at(idx_lead),
             column: column_for_token_at(idx_lead)
           }
         }
       | LEADING_SPACE line_tokens DO NEWLINE group_body LEADING_SPACE END NEWLINE {
           idx_lead = index_for_value(val[0])
           tokens, _ = val[1]
           idx_do = index_for_value(val[2])
           idx_nl = index_for_value(val[3])
           # Discard the LEADING_SPACE before END (val[5])
           result = {
             type: :group,
             tokens: [make_token(:leading_space, val[0], idx_lead)] + tokens + [make_token(:keyword, val[2], idx_do)],
             children: [make_token(:newline, val[3], idx_nl)] + val[4],
             line: line_for_token_at(idx_lead),
             column: column_for_token_at(idx_lead)
           }
         }
       | line_tokens DO TRAILING_SPACE NEWLINE group_body END NEWLINE {
           tokens, start_idx = val[0]
           idx_do = index_for_value(val[1])
           idx_trail = index_for_value(val[2])
           idx_nl = index_for_value(val[3])
           result = {
             type: :group,
             tokens: tokens + [make_token(:keyword, val[1], idx_do), make_token(:trailing_space, val[2], idx_trail)],
             children: [make_token(:newline, val[3], idx_nl)] + val[4],
             line: line_for_token_at(start_idx),
             column: column_for_token_at(start_idx)
           }
         }
       | line_tokens DO TRAILING_SPACE NEWLINE group_body LEADING_SPACE END NEWLINE {
           tokens, start_idx = val[0]
           idx_do = index_for_value(val[1])
           idx_trail = index_for_value(val[2])
           idx_nl = index_for_value(val[3])
           # Discard the LEADING_SPACE before END (val[5])
           result = {
             type: :group,
             tokens: tokens + [make_token(:keyword, val[1], idx_do), make_token(:trailing_space, val[2], idx_trail)],
             children: [make_token(:newline, val[3], idx_nl)] + val[4],
             line: line_for_token_at(start_idx),
             column: column_for_token_at(start_idx)
           }
         }
       | LEADING_SPACE line_tokens DO TRAILING_SPACE NEWLINE group_body LEADING_SPACE END NEWLINE {
           idx_lead = index_for_value(val[0])
           tokens, _ = val[1]
           idx_do = index_for_value(val[2])
           idx_trail = index_for_value(val[3])
           idx_nl = index_for_value(val[4])
           # Discard the LEADING_SPACE before END (val[6])
           result = {
             type: :group,
             tokens: [make_token(:leading_space, val[0], idx_lead)] + tokens + [make_token(:keyword, val[2], idx_do), make_token(:trailing_space, val[3], idx_trail)],
             children: [make_token(:newline, val[4], idx_nl)] + val[5],
             line: line_for_token_at(idx_lead),
             column: column_for_token_at(idx_lead)
           }
         }
       | LEADING_SPACE line_tokens DO TRAILING_SPACE NEWLINE group_body END NEWLINE {
           idx_lead = index_for_value(val[0])
           tokens, _ = val[1]
           idx_do = index_for_value(val[2])
           idx_trail = index_for_value(val[3])
           idx_nl = index_for_value(val[4])
           result = {
             type: :group,
             tokens: [make_token(:leading_space, val[0], idx_lead)] + tokens + [make_token(:keyword, val[2], idx_do), make_token(:trailing_space, val[3], idx_trail)],
             children: [make_token(:newline, val[4], idx_nl)] + val[5],
             line: line_for_token_at(idx_lead),
             column: column_for_token_at(idx_lead)
           }
         }


  # Group body - same structure as document
  group_body: /* empty */ { result = [] }
            | group_lines { result = val[0].flatten.compact }

  group_lines: group_line { result = val[0] }
             | group_lines group_line { result = val[0] + val[1] }

  # Group line - same as document line but need to be careful not to consume LEADING_SPACE before END
  group_line: COMMENT NEWLINE {
                result = [
                  make_token(:comment, val[0], index_for_value(val[0])),
                  make_token(:newline, val[1], index_for_value(val[1]))
                ]
              }
            | NEWLINE { result = [make_token(:newline, val[0], index_for_value(val[0]))] }
            | line_tokens NEWLINE {
                tokens, start_idx = val[0]
                result = [
                  { type: :command, tokens: tokens, line: line_for_token_at(start_idx), column: column_for_token_at(start_idx) },
                  make_token(:newline, val[1], index_for_value(val[1]))
                ]
              }
            | LEADING_SPACE line_tokens NEWLINE {
                idx_lead = index_for_value(val[0])
                tokens, _ = val[1]
                result = [
                  { type: :command, tokens: [make_token(:leading_space, val[0], idx_lead)] + tokens, line: line_for_token_at(idx_lead), column: column_for_token_at(idx_lead) },
                  make_token(:newline, val[2], index_for_value(val[2]))
                ]
              }
            | LEADING_SPACE COMMENT NEWLINE {
                result = [
                  make_token(:leading_space, val[0], index_for_value(val[0])),
                  make_token(:comment, val[1], index_for_value(val[1])),
                  make_token(:newline, val[2], index_for_value(val[2]))
                ]
              }

  # Collect all tokens on a line (anything but NEWLINE and COMMENT)
  # Returns [tokens_array, start_index]
  line_tokens: line_token { result = [[val[0][:token]], val[0][:index]] }
             | line_tokens line_token { result = [val[0][0] << val[1][:token], val[0][1]] }

  line_token: IDENTIFIER { idx = index_for_value(val[0]); result = { token: make_token(:identifier, val[0], idx), index: idx } }
            | STRING { idx = index_for_value(val[0]); result = { token: make_token(:string, val[0], idx), index: idx } }
            | NUMBER { idx = index_for_value(val[0]); result = { token: make_token(:number, val[0], idx), index: idx } }
            | DURATION { idx = index_for_value(val[0]); result = { token: make_token(:duration, val[0], idx), index: idx } }
            | REGEX { idx = index_for_value(val[0]); result = { token: make_token(:regex, val[0], idx), index: idx } }
            | SPACE { idx = index_for_value(val[0]); result = { token: make_token(:space, val[0], idx), index: idx } }
            | TRAILING_SPACE { idx = index_for_value(val[0]); result = { token: make_token(:trailing_space, val[0], idx), index: idx } }
            | COMMA { idx = index_for_value(val[0]); result = { token: make_token(:operator, ",", idx), index: idx } }
            | PLUS { idx = index_for_value(val[0]); result = { token: make_token(:operator, "+", idx), index: idx } }
            | MINUS { idx = index_for_value(val[0]); result = { token: make_token(:operator, "-", idx), index: idx } }
            | AT { idx = index_for_value(val[0]); result = { token: make_token(:operator, "@", idx), index: idx } }
            | TIME_UNIT { idx = index_for_value(val[0]); result = { token: make_token(:time_unit, val[0], idx), index: idx } }

---- header
  require_relative "token"
  require_relative "lexer"
  require_relative "ast"

---- inner
  def parse(str, file: "<unknown>")
    @file = file
    @lexer = DemoTape::Lexer.new
    @tokens = @lexer.tokenize(str)
    @token_index = 0
    @token_indices = {}  # Map token object_id to its index
    do_parse
  end

  def next_token
    token = @tokens.shift
    @current_token_index = @token_index

    # Store the index for this token value
    if token && token[1]
      @token_indices[token[1].object_id] = @current_token_index
    end

    @token_index += 1
    token
  end

  def index_for_value(value)
    @token_indices[value.object_id] || @current_token_index
  end

  def make_token(type, value, index)
    line_info = @lexer.line_map[index] || {}
    token_class = case type
                  when :identifier then DemoTape::Token::Identifier
                  when :string then DemoTape::Token::String
                  when :number then DemoTape::Token::Number
                  when :duration then DemoTape::Token::Duration
                  when :regex then DemoTape::Token::Regex
                  when :time_unit then DemoTape::Token::TimeUnit
                  when :operator then DemoTape::Token::Operator
                  when :space then DemoTape::Token::Space
                  when :leading_space then DemoTape::Token::LeadingSpace
                  when :trailing_space then DemoTape::Token::TrailingSpace
                  when :keyword then DemoTape::Token::Keyword
                  when :comment then DemoTape::Token::Comment
                  when :newline then DemoTape::Token::Newline
                  else DemoTape::Token::Base
                  end

    token_class.new(
      value,
      line: line_info[:line],
      column: line_info[:column],
      raw: line_info[:raw]
    )
  end

  def line_for_token_at(index)
    line_info = @lexer.line_map[index] || {}
    line_info[:line]
  end

  def column_for_token_at(index)
    line_info = @lexer.line_map[index] || {}
    line_info[:column]
  end

  def collect_tokens(*values)
    values.flatten.compact.select { |v| v.is_a?(DemoTape::Token::Base) }
  end

  def on_error(token_id, token_value, value_stack)
    line_info = @lexer.line_map[@current_token_index] || {}
    line_num = line_info[:line] || "?"
    col_num = line_info[:column] || 1
    line_content = line_info[:content] || ""

    token_name = token_to_str(token_id) || token_id.to_s

    error_msg = "Unexpected token #{token_name.inspect} at #{@file}:#{line_num}:#{col_num}:\n"
    error_msg += "  #{line_content.strip}\n"
    error_msg += "  #{' ' * (col_num - line_content.length + line_content.strip.length - 1)}^"

    raise DemoTape::ParseError, error_msg
  end

  def to_commands(parsed)
    commands = []

    parsed.each do |item|
      next unless item.is_a?(Hash)

      if item[:type] == :command
        commands << build_command_from_tokens(item[:tokens], item[:line], item[:column])
      elsif item[:type] == :group
        commands << build_group_from_tokens(item)
      end
    end

    commands
  end

  private

  def build_command_from_tokens(tokens, line, column)
    # Skip leading space tokens
    tokens = tokens.reject {|t| t.is_a?(DemoTape::Token::LeadingSpace) || t.is_a?(DemoTape::Token::TrailingSpace) }

    # First identifier is the command type
    type_token = tokens.find {|t| t.is_a?(DemoTape::Token::Identifier) }
    return nil unless type_token

    type = type_token.value

    # Check if this is a group invocation (lowercase first letter)
    is_group_invocation = type[0].match?(/[^A-Z]/)

    # Build command based on type
    if type == "Set"
      build_set_command(tokens, line, column)
    elsif DemoTape::Command::VALID_KEYS.include?(type)
      build_key_command(tokens, line, column, is_group_invocation)
    else
      build_simple_command(tokens, line, column, is_group_invocation)
    end
  end

  def build_set_command(tokens, line, column)
    # Set option value
    # or Set option value1, value2, value3, value4
    identifiers = tokens.select {|t| t.is_a?(DemoTape::Token::Identifier) }

    option = identifiers[1]&.value

    # Find values after the option
    option_index = tokens.index {|t| t.is_a?(DemoTape::Token::Identifier) && t.value == option }
    value_tokens = tokens[(option_index + 1)..-1].reject {|t| t.is_a?(DemoTape::Token::Space) }

    # Check if we have commas (multiple values)
    has_commas = value_tokens.any? {|t| t.is_a?(DemoTape::Token::Operator) && t.value == "," }

    if has_commas
      # Multiple values - parse comma-separated list
      values = []
      value_tokens.each do |token|
        next if token.is_a?(DemoTape::Token::Operator) && token.value == ","
        values << extract_value(token)
      end

      cmd = DemoTape::Command.new("Set", values, option: option)
    else
      # Single value
      value_token = value_tokens.first
      value = extract_value(value_token)

      cmd = DemoTape::Command.new("Set", value, option: option)
    end

    cmd.line = line
    cmd.column = column
    cmd.tokens = tokens
    cmd.file = @file
    cmd
  end

  def build_key_command(tokens, line, column, is_group_invocation)
    type_token = tokens.find {|t| t.is_a?(DemoTape::Token::Identifier) }
    type = type_token.value

    options = {}

    # Check for @ duration
    at_index = tokens.index {|t| t.is_a?(DemoTape::Token::Operator) && t.value == "@" }
    if at_index
      duration_token = tokens[at_index + 1]
      if duration_token.is_a?(DemoTape::Token::Duration)
        options[:duration] = parse_duration(duration_token)
      elsif duration_token.is_a?(DemoTape::Token::Number)
        options[:duration] = duration_token.value.to_f
      end
    end

    # Check for + keys (key combos)
    plus_indices = tokens.each_index.select {|i| tokens[i].is_a?(DemoTape::Token::Operator) && tokens[i].value == "+" }
    if plus_indices.any?
      keys = []
      plus_indices.each do |plus_index|
        key_token = tokens[plus_index + 1]
        keys << key_token.value if key_token.is_a?(DemoTape::Token::Identifier)
      end
      options[:keys] = keys unless keys.empty?
    end

    # Check for count (number after the key)
    if !at_index
      # No duration, so first number is count
      number_token = tokens.find {|t| t.is_a?(DemoTape::Token::Number) }
      options[:count] = number_token.value if number_token
    else
      # Has duration, look for numbers after the duration token
      duration_token_index = at_index + 1
      count_token = tokens[(duration_token_index + 1)..-1]&.find {|t| t.is_a?(DemoTape::Token::Number) }
      options[:count] = count_token.value if count_token
    end

    cmd = DemoTape::Command.new(type, "", **options)
    cmd.line = line
    cmd.column = column
    cmd.tokens = tokens
    cmd.file = @file

    if is_group_invocation
      cmd.instance_variable_set(:@group_invocation, true)
    end

    cmd
  end

  def build_simple_command(tokens, line, column, is_group_invocation)
    type_token = tokens.find {|t| t.is_a?(DemoTape::Token::Identifier) }
    type = type_token.value

    options = {}

    # Check for @ duration
    at_index = tokens.index {|t| t.is_a?(DemoTape::Token::Operator) && t.value == "@" }
    if at_index
      duration_token = tokens[at_index + 1]
      if duration_token.is_a?(DemoTape::Token::Duration)
        options[:duration] = parse_duration(duration_token)
      elsif duration_token.is_a?(DemoTape::Token::Number)
        options[:duration] = duration_token.value.to_f
      end
    end

    # Find the string/value argument
    string_token = tokens.find {|t| t.is_a?(DemoTape::Token::String) }
    args = string_token ? string_token.value : ""

    # For Sleep, WaitUntil - check for duration/regex
    if type == "Sleep"
      duration_token = tokens.find {|t| t.is_a?(DemoTape::Token::Duration) }
      if duration_token
        options[:duration] = parse_duration(duration_token)
      end
    elsif type == "WaitUntil"
      regex_token = tokens.find {|t| t.is_a?(DemoTape::Token::Regex) }
      if regex_token
        args = regex_token.value
      end
    end

    cmd = DemoTape::Command.new(type, args, **options)
    cmd.line = line
    cmd.column = column
    cmd.tokens = tokens
    cmd.file = @file

    if is_group_invocation
      cmd.instance_variable_set(:@group_invocation, true)
    end

    cmd
  end

  def build_group_from_tokens(item)
    tokens = item[:tokens].reject {|t| t.is_a?(DemoTape::Token::LeadingSpace) || t.is_a?(DemoTape::Token::TrailingSpace) || t.is_a?(DemoTape::Token::Keyword) }

    # Second identifier is the group name
    identifiers = tokens.select {|t| t.is_a?(DemoTape::Token::Identifier) }
    name = identifiers[1]&.value || ""

    # Build children commands
    children_items = item[:children].select {|child| child.is_a?(Hash) }
    children = children_items.map do |child_item|
      if child_item[:type] == :command
        build_command_from_tokens(child_item[:tokens], child_item[:line], child_item[:column])
      elsif child_item[:type] == :group
        build_group_from_tokens(child_item)
      end
    end.compact

    cmd = DemoTape::Command.new("Group", name, children: children)
    cmd.line = item[:line]
    cmd.column = item[:column]
    cmd.tokens = item[:tokens]
    cmd.file = @file
    cmd
  end

  def extract_value(token)
    case token
    when DemoTape::Token::Number
      token.value
    when DemoTape::Token::String
      token.value
    when DemoTape::Token::Identifier
      # Could be a boolean or identifier
      case token.value
      when "true" then true
      when "false" then false
      else token.value
      end
    when DemoTape::Token::Duration
      parse_duration(token)
    else
      token.value
    end
  end

  def parse_duration(duration_token)
    value = duration_token.value
    number = value[:number]
    unit = value[:unit]

    # Convert to seconds
    case unit
    when "ms"
      number / 1000.0
    when "s"
      number.to_f
    when "m"
      number * 60.0
    when "h"
      number * 3600.0
    else
      number.to_f
    end
  end

---- footer
