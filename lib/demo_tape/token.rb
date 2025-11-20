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
    end

    class Identifier < Base; end
    class String < Base; end
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
