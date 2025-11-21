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
           idx_end = index_for_value(val[4])
           result = {
             type: :group,
             tokens: tokens + [make_token(:keyword, val[1], idx_do), make_token(:keyword, val[4], idx_end)],
             children: [make_token(:newline, val[2], idx_nl)] + val[3],
             line: line_for_token_at(start_idx),
             column: column_for_token_at(start_idx)
           }
         }
       | line_tokens DO NEWLINE group_body LEADING_SPACE END NEWLINE {
           tokens, start_idx = val[0]
           idx_do = index_for_value(val[1])
           idx_nl = index_for_value(val[2])
           idx_end = index_for_value(val[5])
           # Discard the LEADING_SPACE before END (val[4])
           result = {
             type: :group,
             tokens: tokens + [make_token(:keyword, val[1], idx_do), make_token(:keyword, val[5], idx_end)],
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
           idx_end = index_for_value(val[5])
           result = {
             type: :group,
             tokens: [make_token(:leading_space, val[0], idx_lead)] + tokens + [make_token(:keyword, val[2], idx_do), make_token(:keyword, val[5], idx_end)],
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
           idx_end = index_for_value(val[6])
           # Discard the LEADING_SPACE before END (val[5])
           result = {
             type: :group,
             tokens: [make_token(:leading_space, val[0], idx_lead)] + tokens + [make_token(:keyword, val[2], idx_do), make_token(:keyword, val[6], idx_end)],
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
           idx_end = index_for_value(val[5])
           result = {
             type: :group,
             tokens: tokens + [make_token(:keyword, val[1], idx_do), make_token(:trailing_space, val[2], idx_trail), make_token(:keyword, val[5], idx_end)],
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
           idx_end = index_for_value(val[6])
           # Discard the LEADING_SPACE before END (val[5])
           result = {
             type: :group,
             tokens: tokens + [make_token(:keyword, val[1], idx_do), make_token(:trailing_space, val[2], idx_trail), make_token(:keyword, val[6], idx_end)],
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
           idx_end = index_for_value(val[7])
           # Discard the LEADING_SPACE before END (val[6])
           result = {
             type: :group,
             tokens: [make_token(:leading_space, val[0], idx_lead)] + tokens + [make_token(:keyword, val[2], idx_do), make_token(:trailing_space, val[3], idx_trail), make_token(:keyword, val[7], idx_end)],
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
           idx_end = index_for_value(val[6])
           result = {
             type: :group,
             tokens: [make_token(:leading_space, val[0], idx_lead)] + tokens + [make_token(:keyword, val[2], idx_do), make_token(:trailing_space, val[3], idx_trail), make_token(:keyword, val[6], idx_end)],
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
            | MULTILINE_STRING { idx = index_for_value(val[0]); result = { token: make_token(:multiline_string, val[0], idx), index: idx } }
            | NUMBER { idx = index_for_value(val[0]); result = { token: make_token(:number, val[0], idx), index: idx } }
            | DURATION { idx = index_for_value(val[0]); result = { token: make_token(:duration, val[0], idx), index: idx } }
            | REGEX { idx = index_for_value(val[0]); result = { token: make_token(:regex, val[0], idx), index: idx } }
            | SPACE { idx = index_for_value(val[0]); result = { token: make_token(:space, val[0], idx), index: idx } }
            | TRAILING_SPACE { idx = index_for_value(val[0]); result = { token: make_token(:trailing_space, val[0], idx), index: idx } }
            | COMMA { idx = index_for_value(val[0]); result = { token: make_token(:operator, ",", idx), index: idx } }
            | PLUS { idx = index_for_value(val[0]); result = { token: make_token(:operator, "+", idx), index: idx } }
            | AT { idx = index_for_value(val[0]); result = { token: make_token(:operator, "@", idx), index: idx } }
            | TIME_UNIT { idx = index_for_value(val[0]); result = { token: make_token(:time_unit, val[0], idx), index: idx } }

---- header

---- inner
  include Helpers

  def parse(str, file: "<unknown>")
    @file = file
    @lexer = DemoTape::Lexer.new
    @tokens = @lexer.tokenize(str)
    @token_index = 0
    @token_indices = {}  # Map token object_id to its index
    validate_tree!(do_parse)
  end

---- footer
