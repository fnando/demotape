class DemoTape::SimpleParser
rule
  # Match lines - each line is either comment+newline or command tokens+newline  
  document: lines { result = val[0].flatten }
          | /* empty */ { result = [] }
  
  lines: line { result = [val[0]] }
       | lines line { result = val[0] + val[1] }
  
  # A line ends with NEWLINE
  line: COMMENT NEWLINE { result = [[:comment, val[0]], [:newline, val[1]]] }
      | NEWLINE { result = [[:newline, val[0]]] }
      | line_tokens NEWLINE { result = [{ type: :command, tokens: val[0] }, [:newline, val[1]]] }
  
  # Line tokens: anything that's not a newline
  line_tokens: line_token { result = [val[0]] }
             | line_tokens line_token { result = val[0] << val[1] }
  
  line_token: IDENTIFIER { result = [:id, val[0]] }
            | STRING { result = [:str, val[0]] }
            | SPACE { result = [:sp, val[0]] }
            | LEADING_SPACE { result = [:lsp, val[0]] }

---- inner
  def parse(tokens)
    @tokens = tokens
    do_parse
  end
  
  def next_token
    @tokens.shift
  end
