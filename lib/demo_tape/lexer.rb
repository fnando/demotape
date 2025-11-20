# frozen_string_literal: true

module DemoTape
  class Lexer
    def self.tokenize(content)
      new.tokenize(content)
    end

    attr_reader :line_map

    def tokenize(content)
      tokens = []
      @line_map = {}
      @line_number = 0
      token_index = 0
      in_multiline = false
      multiline_content = []
      multiline_start_line = 0
      multiline_start_col = 1

      content.each_line do |line|
        @line_number += 1
        original_line = line.dup
        stripped_line = line.strip

        # Handle multiline string collection
        if in_multiline
          if stripped_line == '"""'
            # End of multiline string
            in_multiline = false

            # Create the multiline string token,
            # but first, strip the initial linebreak after the opening quotes
            multiline_content.first.gsub!(/\A\r?\n/, "")
            multiline_text = multiline_content.join("\n")
            @line_map[token_index] = {
              line: multiline_start_line,
              column: multiline_start_col,
              content: '"""',
              raw: '"""..."""'
            }
            tokens << [:STRING, multiline_text]
            token_index += 1

            # Add NEWLINE token after multiline string
            @line_map[token_index] = {
              line: @line_number,
              column: 1,
              content: '"""'
            }
            tokens << [:NEWLINE, "\n"]
            token_index += 1

            multiline_content = []
          else
            # Collect line content (preserve original spacing)
            multiline_content << line.chomp
          end
          next
        end

        # Handle comments - emit as tokens
        if stripped_line.start_with?("#")
          @line_map[token_index] = {
            line: @line_number,
            column: 1,
            content: original_line.chomp,
            raw: stripped_line
          }
          tokens << [:COMMENT, stripped_line]
          token_index += 1

          @line_map[token_index] = {
            line: @line_number,
            column: 1,
            content: original_line.chomp
          }
          tokens << [:NEWLINE, "\n"]
          token_index += 1
          next
        end

        # Handle empty lines - emit just NEWLINE
        if stripped_line.empty?
          @line_map[token_index] = {
            line: @line_number,
            column: 1,
            content: ""
          }
          tokens << [:NEWLINE, "\n"]
          token_index += 1
          next
        end

        # Tokenize the original line (preserving all spaces)
        line_tokens = tokenize_line(line.chomp)

        # Convert first SPACE token to LEADING_SPACE if it exists
        if line_tokens.any? && line_tokens[0][0] == :SPACE
          line_tokens[0][0] = :LEADING_SPACE
        end

        # Convert last SPACE token (before end) to TRAILING_SPACE if it exists
        last_non_newline = line_tokens.length - 1

        while last_non_newline >= 0 &&
              line_tokens[last_non_newline][0] == :NEWLINE
          last_non_newline -= 1
        end

        if last_non_newline >= 0 && line_tokens[last_non_newline][0] == :SPACE
          line_tokens[last_non_newline][0] = :TRAILING_SPACE
        end

        # Check if any token starts a multiline string
        multiline_index = line_tokens.find_index do |t|
          t[0] == :TRIPLE_QUOTE_START
        end

        if multiline_index
          # Process tokens before the triple quote
          line_tokens[0...multiline_index].each do |token|
            col = token[2] || 1
            raw = token[3] || token[1].to_s

            @line_map[token_index] = {
              line: @line_number,
              column: col,
              content: original_line.chomp,
              raw: raw
            }

            token.pop if token.size == 4
            token.pop if token.size == 3
            token_index += 1
          end

          tokens.concat(line_tokens[0...multiline_index])

          # Start multiline mode
          in_multiline = true
          multiline_start_line = @line_number
          multiline_start_col = line_tokens[multiline_index][2] || 1
          multiline_content = []
          next
        end

        # Store line metadata separately indexed by token position
        line_tokens.each do |token|
          col = token[2] || 1
          raw = token[3] || token[1].to_s

          @line_map[token_index] = {
            line: @line_number,
            column: col,
            content: original_line.chomp,
            raw: raw
          }

          # Remove column and raw from token before adding to tokens array
          token.pop if token.size == 4  # Remove raw
          token.pop if token.size == 3  # Remove column
          token_index += 1
        end

        tokens.concat(line_tokens)

        @line_map[token_index] = {
          line: @line_number,
          column: 1,
          content: original_line.chomp
        }

        tokens << [:NEWLINE, "\n"]
        token_index += 1
      end

      tokens
    end

    private def tokenize_line(line)
      tokens = []
      scanner = StringScanner.new(line)

      until scanner.eos?
        # Track column position before scanning token
        col = scanner.pos + 1

        # Whitespace (emit as token instead of skipping)
        if scanner.scan(/\s+/)
          tokens << [:SPACE, scanner[0], col]
          next
        end

        # Triple-quoted string start
        if scanner.scan('"""')
          tokens << [:TRIPLE_QUOTE_START, '"""', col, '"""']

        # Double-quoted string (with escape support)
        elsif scanner.scan(/"((?:[^"\\]|\\.)*)"/)
          tokens << [:STRING, unescape_string(scanner[1]), col, scanner[0]]

        # Single-quoted string (with escape support)
        elsif scanner.scan(/'((?:[^'\\]|\\.)*)'/) # rubocop:disable Lint/DuplicateBranch
          tokens << [:STRING, unescape_string(scanner[1]), col, scanner[0]]

        # Regex pattern (between forward slashes)
        elsif scanner.scan(%r{/((?:[^/\\]|\\.)*)/})
          tokens << [:REGEX, scanner[1], col, scanner[0]]

        # Duration (number + time unit - any identifier)
        elsif scanner.scan(/(\d+(?:\.\d+)?|\.\d+)([a-zA-Z]+)/)
          tokens << [
            :NUMBER,
            scanner[1].include?(".") ? scanner[1].to_f : scanner[1].to_i,
            col,
            scanner[1]
          ]
          # TIME_UNIT starts after the number
          time_unit_col = col + scanner[1].length
          tokens << [:TIME_UNIT, scanner[2], time_unit_col, scanner[2]]

        # Number
        elsif scanner.scan(/\d+(?:\.\d+)?|\.\d+/)
          value = scanner[0].include?(".") ? scanner[0].to_f : scanner[0].to_i
          tokens << [:NUMBER, value, col, scanner[0]]

        # At symbol
        elsif scanner.scan("@")
          tokens << [:AT, "@", col, "@"]

        # Plus symbol
        elsif scanner.scan("+")
          tokens << [:PLUS, "+", col, "+"]

        # Comma
        elsif scanner.scan(",")
          tokens << [:COMMA, ",", col, ","]

        # Identifier (including dot notation for nested options)
        elsif scanner.scan(/[a-zA-Z_][\w.]*/)
          # Check for keywords
          value = scanner[0]
          token_type = case value
                       when "do" then :DO
                       when "end" then :END
                       else :IDENTIFIER
                       end
          tokens << [token_type, value, col, value]

        # Word
        elsif scanner.scan(/\S+/)
          tokens << [:WORD, scanner[0], col, scanner[0]]

        else
          break
        end
      end

      tokens
    end

    def unescape_string(str)
      # First handle Unicode escapes to avoid double-processing
      str = str.gsub(/\\u([0-9a-fA-F]{4})/) do
        code_point = Regexp.last_match(1).to_i(16)

        # Check if this is a high surrogate (0xD800-0xDBFF)
        if code_point.between?(0xD800, 0xDBFF)
          # Look ahead for low surrogate
          remaining = Regexp.last_match.post_match

          if remaining =~ /^\\u([dD][c-fC-F][0-9a-fA-F]{2})/
            low_surrogate = Regexp.last_match(1).to_i(16)

            # Combine surrogates into single code point
            full_code_point = 0x10000 +
                              ((code_point - 0xD800) << 10) +
                              (low_surrogate - 0xDC00)

            # Return the character and mark the low surrogate for removal
            "#{[full_code_point].pack('U*')}\u0000SKIP6"
          else
            # Orphaned high surrogate, keep as-is
            [code_point].pack("U*")
          end
        elsif code_point.between?(0xDC00, 0xDFFF)
          # Low surrogate without high surrogate, skip if marked
          ""
        else
          [code_point].pack("U*")
        end
      end

      # Remove skip markers left by surrogate pair processing
      str = str.gsub("\x00SKIP6", "")

      # Handle 8-digit Unicode escapes
      str = str.gsub(/\\U([0-9a-fA-F]{8})/) do
        code_point = Regexp.last_match(1).to_i(16)
        [code_point].pack("U*")
      end

      # Handle other escape sequences
      str.gsub(/\\(.)/) do
        case Regexp.last_match(1)
        when "n" then "\n"
        when "t" then "\t"
        when "r" then "\r"
        when "\\" then "\\"
        when '"' then '"'
        when "'" then "'"
        else Regexp.last_match(1) # Keep other escapes as-is
        end
      end
    end
  end
end
