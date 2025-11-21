# frozen_string_literal: true

module DemoTape
  class Parser < Racc::Parser
    module Helpers
      def validate_tree!(tree)
        tree.each do |item|
          case item
          when Hash
            if item[:type] == :command
              Rules.validate_command!(@file, item[:tokens])
            elsif item[:type] == :group
              Rules.validate_group!(@file, item)
            end
          end
        end

        tree
      end

      def next_token
        token = @tokens.shift
        @current_token_index = @token_index

        # Store the index for this token value
        @token_indices[token[1]] = @current_token_index if token && token[1]

        @token_index += 1
        token
      end

      def index_for_value(value)
        @token_indices[value] || @current_token_index
      end

      def make_token(type, value, index)
        line_info = @lexer.line_map[index] || {}
        token_class = case type
                      when :identifier then Token::Identifier
                      when :string then Token::String
                      when :multiline_string then Token::MultilineString
                      when :number then Token::Number
                      when :duration then Token::Duration
                      when :regex then Token::Regex
                      when :operator then Token::Operator
                      when :space then Token::Space
                      when :leading_space then Token::LeadingSpace
                      when :trailing_space then Token::TrailingSpace
                      when :keyword then Token::Keyword
                      when :comment then Token::Comment
                      when :newline then Token::Newline
                      else
                        raise "Unknown token type: #{type.inspect}"
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
        values.flatten.compact.select {|v| v.is_a?(Token::Base) }
      end

      def on_error(token_id, _token_value, _value_stack)
        line_info = @lexer.line_map[@current_token_index] || {}
        line_num = line_info[:line] || "?"
        col_num = line_info[:column] || 1
        line_content = line_info[:content] || ""

        token_name = token_to_str(token_id) || token_id.to_s

        error_msg = "Unexpected token #{token_name.inspect} at " \
                    "#{@file}:#{line_num}:#{col_num}:\n"
        error_msg += "  #{line_content.strip}\n"
        space_count = col_num -
                      line_content.length +
                      line_content.strip.length -
                      1
        error_msg += "  #{' ' * space_count}^"

        raise ParseError, error_msg
      end

      def to_commands(parsed)
        commands = []

        parsed.each do |item|
          next unless item.is_a?(Hash)

          if item[:type] == :command
            commands << build_command_from_tokens(
              item[:tokens],
              item[:line],
              item[:column]
            )
          elsif item[:type] == :group
            commands << build_group_from_tokens(item)
          end
        end

        commands.each(&:prepare!)
        commands
      end

      def build_command_from_tokens(tokens, line, column)
        # Skip leading space tokens
        tokens = tokens.reject(&:around_space?)

        # First identifier is the command type
        type_token = tokens.find(&:identifier?)
        return unless type_token

        type = type_token.value

        # Check if this is a group invocation (lowercase first letter)
        is_group_invocation = type[0].match?(/[^A-Z]/)

        # Build command based on type
        if type == "Set"
          build_set_command(tokens, line, column)
        elsif Command::VALID_KEYS.include?(type)
          build_key_command(tokens, line, column, is_group_invocation)
        else
          build_simple_command(tokens, line, column, is_group_invocation)
        end
      end

      def build_set_command(tokens, line, column)
        # Set option value
        # or Set option value1, value2, value3, value4
        identifiers = tokens.select(&:identifier?)

        # Set the option name
        option = identifiers[1]&.value

        # Find values after the option
        option_index = tokens.index {|t| t.identifier?(option) }
        value_tokens = tokens[(option_index + 1)..-1].reject(&:space?)

        # Check if we have commas (multiple values)
        has_commas = value_tokens.any?(&:comma_operator?)

        # Extract line content for error
        content = tokens.map(&:raw).join

        if has_commas
          # Multiple values - parse comma-separated list
          values = []
          value_tokens.each do |token|
            next if token.comma_operator?

            values << extract_value(token, content)
          end

          cmd = Command.new("Set", values, option: option)
        else
          # Single value
          value_token = value_tokens.first
          value = extract_value(value_token, content)

          cmd = Command.new("Set", value, option: option)
        end

        cmd.line = line
        cmd.column = column
        cmd.tokens = tokens
        cmd.file = @file
        cmd
      end

      def compute_duration!(token, options, content)
        if token&.number?
          options[:duration] = token.value.to_f
          return
        end

        return unless token

        options[:duration] = parse_duration(token, content)
      end

      def compute_at_duration!(tokens, options)
        at_index = tokens.index(&:at_operator?)
        return unless at_index

        token = tokens[at_index + 1]

        compute_duration!(token, options, tokens.map(&:raw).join)
      end

      def compute_count!(tokens, options)
        at_index = tokens.index(&:at_operator?)

        if at_index
          # Has duration, look for numbers after the duration token
          duration_token_index = at_index + 1
          count_token = tokens[(duration_token_index + 1)..-1]&.find(&:number?)
          options[:count] = count_token.value if count_token
        else
          # No duration, so first number is count
          number_token = tokens.find(&:number?)
          options[:count] = number_token.value if number_token
        end
      end

      def build_key_command(tokens, line, column, is_group_invocation)
        type_token = tokens.find(&:identifier?)
        type = type_token.value

        options = {}

        compute_at_duration!(tokens, options)

        # Check for + keys (key combos)
        plus_indices = tokens.filter_map.each_with_index do |token, index|
          index if token.plus_operator?
        end

        if plus_indices.any?
          keys = []

          plus_indices.each do |plus_index|
            key_token = tokens[plus_index + 1]
            keys << key_token.value if key_token.identifier?
          end

          options[:keys] = keys
        end

        compute_count!(tokens, options)

        cmd = Command.new(type, "", **options)
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
        type_token = tokens.find(&:identifier?)
        type = type_token.value

        options = {}

        # Check for @ duration
        compute_at_duration!(tokens, options)

        # Find the string/value argument
        string_token = tokens.find(&:string?)
        args = string_token ? string_token.value : ""

        # For Sleep, Wait - check for duration/number
        if %w[
          Sleep
          Wait
        ].include?(type) && (tokens[2].duration? || tokens[2].number?)
          compute_duration!(tokens[2], options, tokens.map(&:raw).join)
        elsif type == "WaitUntil"
          regex_token = tokens.find(&:regex?)
          args = regex_token.value if regex_token
        end

        cmd = Command.new(type, args, **options)
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
        tokens = item[:tokens].reject do |t|
          t.around_space? || t.keyword?
        end

        # Second identifier is the group name
        identifiers = tokens.select(&:identifier?)
        name = identifiers[1]&.value || ""

        # Build children commands
        children_items = item[:children].select {|child| child.is_a?(Hash) }

        children = children_items.filter_map do |child_item|
          if child_item[:type] == :command
            build_command_from_tokens(
              child_item[:tokens],
              child_item[:line],
              child_item[:column]
            )
          end
        end

        cmd = Command.new(item[:tokens].first.value, name, children:)
        cmd.line = item[:line]
        cmd.column = item[:column]
        cmd.tokens = item[:tokens]
        cmd.file = @file
        cmd
      end

      def extract_value(token, content)
        case token
        when Token::Identifier
          case token.value
          when "true" then true
          when "false" then false
          else
            token.value
          end
        when Token::Duration
          parse_duration(token, content)
        else
          token.value
        end
      end

      def parse_duration(token, _content)
        value = token.value
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
        else # rubocop:disable Lint/DuplicateBranch
          number.to_f
        end
      end
    end
  end
end
