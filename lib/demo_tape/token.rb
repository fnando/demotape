# frozen_string_literal: true

module DemoTape
  module Token
    class Base
      attr_reader :value, :raw, :line, :column

      def initialize(value, line: nil, column: nil, raw: nil)
        @value = value
        @raw = raw || value.to_s
        @line = line
        @column = column
      end

      def meta?
        identifier?("Include") ||
          identifier?("Output") ||
          identifier?("Require") ||
          identifier?("Set")
      end

      def group?
        identifier?("Group")
      end

      def supports_block?
        group?
      end

      def regex?
        is_a?(Token::Regex)
      end

      def keyword?(wanted = nil)
        is_a?(Token::Keyword) && (wanted.nil? || value == wanted)
      end

      def string?
        is_a?(Token::String)
      end

      def multiline_string?
        is_a?(Token::MultilineString)
      end

      def number?
        is_a?(Token::Number)
      end

      def duration?
        is_a?(Token::Duration)
      end

      def operator?(wanted = nil)
        is_a?(Token::Operator) && (wanted.nil? || value == wanted)
      end

      def comma_operator?
        operator?(",")
      end

      def at_operator?
        operator?("@")
      end

      def plus_operator?
        operator?("+")
      end

      def around_space?
        is_a?(Token::TrailingSpace) || is_a?(Token::LeadingSpace)
      end

      def space?
        is_a?(Token::Space)
      end

      def any_space?
        around_space? || space?
      end

      def comment?
        is_a?(Token::Comment)
      end

      def newline?
        is_a?(Token::Newline)
      end

      def identifier?(wanted = nil)
        is_a?(Token::Identifier) && (wanted.nil? || value == wanted)
      end
    end

    class Identifier < Base; end
    class String < Base; end
    class MultilineString < Base; end
    class Number < Base; end
    class Duration < Base; end
    class Regex < Base; end
    class TimeUnit < Base; end
    class Operator < Base; end
    class Space < Base; end
    class LeadingSpace < Base; end
    class TrailingSpace < Base; end
    class Keyword < Base; end
    class Comment < Base; end
    class Newline < Base; end
  end
end
