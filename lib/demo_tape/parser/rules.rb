# frozen_string_literal: true

module DemoTape
  class Parser < Racc::Parser
    class Rules
      module Helpers
        def raise_error(token:, file:, content:, message:)
          line = token.line
          column = token.column
          leading_spaces = content[/^\s*/].size

          error_message = [
            "#{message} at #{file}:#{line}:#{column}:",
            "  #{content}",
            "  #{' ' * (column - 1 + leading_spaces)}^"
          ].join("\n")

          raise DemoTape::ParseError, error_message
        end
      end

      class Identifier
        attr_reader :names, :expectations

        def initialize(*names)
          @names = names
          @expectations = [self]
        end

        def valid?(other, *)
          return false unless other.identifier?

          results = names.map do |name|
            case name
            when String
              other.value == name
            when Regexp
              other.value.match?(name)
            end
          end

          results.any?
        end

        def |(other)
          Any.new(self, other)
        end

        def +(other)
          expectations << other
          self
        end
      end

      class Any
        def initialize(*types)
          @types = types
        end

        def valid?(*)
          @types.any? { it.valid?(*) }
        end
      end

      class Duration
        include Helpers

        def valid?(other, file, content)
          return false unless other.duration?

          unit = other.value[:unit]
          return true if %w[ms s m h].include?(unit)

          raise_error token: other,
                      file:,
                      content:,
                      message: "Invalid unit #{unit.inspect} in duration"
        end
      end

      class Number
        def valid?(other, *)
          other.number?
        end
      end

      class Operator
        def initialize(*operators)
          @operators = operators
        end

        def valid?(other, *)
          other.operator? && @operators.include?(other.value)
        end
      end

      class Boolean
        def valid?(other, *)
          other.identifier? && %w[true false].include?(other.value)
        end
      end

      class Regex
        include Helpers

        def valid?(other, file, content)
          return false unless other.regex?

          error = other.value[:error]

          return true unless error

          raise_error(
            token: other,
            file:,
            content:,
            message: "Invalid regular expression (#{error})"
          )
        end
      end

      class StringToken
        def initialize(enum)
          @enum = enum
        end

        def valid?(other, *)
          (other.string? || other.multiline_string?) &&
            (@enum.empty? || @enum.include?(other.value))
        end
      end

      module ClassMethods
        include Helpers

        def validate_key_combos!(tokens, file, content)
          return unless tokens.any?(&:plus_operator?)

          operator_indices = tokens.each_index
                                   .select {|i| tokens[i].plus_operator? }

          operator_indices.each do |index|
            before = tokens[index - 1]
            after = tokens[index + 1]

            next unless before.any_space? || after.any_space?

            # Invalid spacing around '+'
            raise_error token: tokens[index],
                        file:,
                        content:,
                        message: "Invalid spacing around '+' in key combo"
          end
        end

        def validate_group!(file, group)
          validate_token_supports_block!(file, group)

          commands = group[:children].select { it.is_a?(Hash) }
          commands.each { validate_command!(file, it[:tokens]) }
        end

        def validate_token_supports_block!(file, group)
          tokens = group[:tokens].reject(&:any_space?)
          token = tokens.find(&:identifier?)

          return if token.supports_block?

          do_token = tokens.find { it.keyword?("do") }

          raise_error file:,
                      content: group[:tokens][0..-2].map(&:raw).join,
                      token: do_token,
                      message: "Command #{token.value.inspect} " \
                               "doesn't support blocks"
        end

        def validate_command!(file, tokens)
          content = tokens.map(&:raw).join
          actionable_tokens = tokens.reject(&:any_space?).reject(&:comment?)

          return if actionable_tokens.empty?

          validate_key_combos!(tokens, file, content)

          results = rules.map do |rule|
            matches = []
            expectations = rule.expectations

            all_valid =
              actionable_tokens.zip(expectations).all? do |token, expectation|
                valid = expectation&.valid?(token, file, content)
                matches << token if valid
                valid
              end

            [all_valid, matches]
          end

          return if results.any?(&:first)

          closest_match = results.reject { it[1].nil? }.max_by { it[1].size }
          invalid_token = actionable_tokens[closest_match[1].size]

          raise_error token: invalid_token,
                      file:,
                      content:,
                      message: "Unexpected token #{invalid_token.raw.inspect}"
        end

        def rules
          @rules ||= []
        end

        def identifier(*names)
          Identifier.new(*names)
        end

        def duration
          Duration.new
        end

        def number
          Number.new
        end

        def boolean
          Boolean.new
        end

        def string(*enum)
          StringToken.new(enum)
        end

        def operator(*operators)
          Operator.new(*operators)
        end

        def regex
          Regex.new
        end
      end

      extend ClassMethods

      # Group invocations
      rules.push identifier(/^[a-z0-9_]+$/)

      key = identifier(*Command::VALID_KEYS) | number

      # KEY+KEY
      rules.push identifier(*Command::KEY_MAPPING.keys) + operator("+") + key
      rules.push identifier(*Command::KEY_MAPPING.keys) +
                 operator("+") +
                 key +
                 number

      # KEY+KEY+KEY
      rules.push identifier(*Command::KEY_MAPPING.keys) +
                 operator("+") +
                 key +
                 operator("+") +
                 key
      rules.push identifier(*Command::KEY_MAPPING.keys) +
                 operator("+") +
                 key +
                 operator("+") +
                 key +
                 number

      # KEY+KEY+KEY+KEY
      key_combo = identifier(*Command::KEY_MAPPING.keys) +
                  operator("+") +
                  key +
                  operator("+") +
                  key +
                  operator("+") +
                  key
      rules.push key_combo
      rules.push key_combo.dup + number

      # COMMAND
      rules.push identifier(
        *Command::KEY_MAPPING.keys,
        "Screenshot", "Paste", "Clear", "Pause", "Resume"
      )

      # KEY@DURATION COUNT
      rules.push identifier(*Command::KEY_MAPPING.keys) +
                 operator("@") +
                 duration +
                 number

      # KEY COUNT
      rules.push identifier(*Command::KEY_MAPPING.keys) +
                 number

      # KEY@NUMBER COUNT
      rules.push identifier(*Command::KEY_MAPPING.keys) +
                 operator("@") +
                 number +
                 number

      # KEY@DURATION
      rules.push identifier(*Command::KEY_MAPPING.keys) +
                 operator("@") +
                 duration

      # KEY@NUMBER
      rules.push identifier(*Command::KEY_MAPPING.keys) +
                 operator("@") +
                 number

      # COMMAND STRING
      rules.push identifier("Type", "TypeFile", "Send", "Copy", "Screenshot",
                            "Run", "Require", "Output", "Include") +
                 string

      # COMMAND DURATION
      rules.push identifier("Sleep", "Wait") +
                 duration

      # COMMAND NUMBER
      rules.push identifier("Sleep", "Wait") +
                 number

      # COMMAND@DURATION STRING
      rules.push identifier("Run", "Type") +
                 operator("@") +
                 duration +
                 string

      # WaitUntilDone
      rules.push identifier("WaitUntilDone")
      rules.push identifier("WaitUntilDone") + operator("@") + duration
      rules.push identifier("WaitUntilDone") + operator("@") + number

      # WaitUntil
      rules.push identifier("WaitUntil") + regex
      rules.push identifier("WaitUntil") + operator("@") + duration + regex
      rules.push identifier("WaitUntil") + operator("@") + number + regex

      # Set attribute DURATION
      rules.push identifier("Set") +
                 identifier("loop_delay", "run_sleep", "run_enter_delay",
                            "typing_speed", "timeout") +
                 duration

      # Set attribute BOOLEAN
      rules.push identifier("Set") +
                 identifier("loop", "cursor_blink") +
                 boolean

      # Set attribute NUMBER
      rules.push identifier("Set") +
                 identifier("width", "height", "cursor_width", "font_size",
                            "padding", "margin", "loop_delay", "line_height",
                            "border_radius", "typing_speed", "timeout") +
                 number

      # Set attribute STRING
      rules.push identifier("Set") +
                 identifier("theme", "font_family", "margin_fill", "shell") +
                 string

      # Set cursor_style STRING
      rules.push identifier("Set") +
                 identifier("cursor_style") +
                 string("block", "underline", "bar")

      # Set theme.property STRING
      rules.push identifier("Set") +
                 identifier(/^theme\.[a-z0-9_]+$/) +
                 string

      # Set attribute NUMBER COMMA NUMBER
      rules.push identifier("Set") +
                 identifier("padding", "margin") +
                 number +
                 operator(",") +
                 number

      # Set attribute NUMBER COMMA NUMBER COMMA NUMBER
      rules.push identifier("Set") +
                 identifier("padding", "margin") +
                 number +
                 operator(",") +
                 number +
                 operator(",") +
                 number

      # Set attribute NUMBER COMMA NUMBER COMMA NUMBER COMMA NUMBER
      rules.push identifier("Set") +
                 identifier("padding", "margin") +
                 number +
                 operator(",") +
                 number +
                 operator(",") +
                 number +
                 operator(",") +
                 number
    end
  end
end
