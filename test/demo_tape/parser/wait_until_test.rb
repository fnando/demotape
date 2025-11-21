# frozen_string_literal: true

require "test_helper"

class ParserWaitUntilTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses WaitUntil with simple regex" do
    result = parse("WaitUntil /line 10/\n")

    assert_equal 2, result.length

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].length

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "WaitUntil", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][1]

    assert_instance_of DemoTape::Token::Regex, command[:tokens][2]
    assert_equal({pattern: /line 10/}, command[:tokens][2].value)

    assert_instance_of DemoTape::Token::Newline, result[1]
  end

  test "parses WaitUntil with duration" do
    result = parse("WaitUntil@30s /Done!/\n")

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 5, command[:tokens].length

    assert_equal "WaitUntil", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Operator, command[:tokens][1]
    assert_equal "@", command[:tokens][1].value

    assert_instance_of DemoTape::Token::Duration, command[:tokens][2]
    assert_equal({number: 30, unit: "s", raw: "30s"}, command[:tokens][2].value)

    assert_instance_of DemoTape::Token::Space, command[:tokens][3]

    assert_instance_of DemoTape::Token::Regex, command[:tokens][4]
    assert_equal({pattern: /Done!/}, command[:tokens][4].value)
  end

  test "parses WaitUntil with anchored regex" do
    result = parse("WaitUntil /^Ready$/\n")

    command = result[0]
    assert_equal({pattern: /^Ready$/}, command[:tokens][2].value)
  end

  test "parses WaitUntil with complex regex" do
    result = parse("WaitUntil /error.*occurred/\n")

    command = result[0]
    assert_equal({pattern: /error.*occurred/}, command[:tokens][2].value)
  end

  test "parses WaitUntil with character class regex" do
    result = parse("WaitUntil /[0-9]+%/\n")

    command = result[0]
    assert_equal({pattern: /[0-9]+%/}, command[:tokens][2].value)
  end

  test "parses WaitUntil with escaped characters in regex" do
    result = parse('WaitUntil /\\\d+ items/')

    command = result[0]
    assert_equal({pattern: /\\d+ items/}, command[:tokens][2].value)
  end

  test "parses WaitUntil with duration in milliseconds" do
    result = parse("WaitUntil@500ms /ready/\n")

    command = result[0]
    assert_equal({number: 500, unit: "ms", raw: "500ms"},
                 command[:tokens][2].value)
    assert_equal({pattern: /ready/}, command[:tokens][4].value)
  end

  test "parses WaitUntil with duration in minutes" do
    result = parse("WaitUntil@2m /complete/\n")

    command = result[0]
    assert_equal({number: 2, unit: "m", raw: "2m"}, command[:tokens][2].value)
  end

  test "parses WaitUntil with leading space" do
    result = parse("  WaitUntil /test/\n")

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 4, command[:tokens].length

    assert_instance_of DemoTape::Token::LeadingSpace, command[:tokens][0]
    assert_equal "  ", command[:tokens][0].value

    assert_equal "WaitUntil", command[:tokens][1].value
    assert_equal({pattern: /test/}, command[:tokens][3].value)
  end

  test "parses multiple WaitUntil commands" do
    source = <<~TAPE
      WaitUntil /first/
      WaitUntil@10s /second/
      WaitUntil /third/
    TAPE

    result = parse(source)

    commands = result
               .select {|item| item.is_a?(Hash) && item[:type] == :command }
    assert_equal 3, commands.length

    assert_equal({pattern: /first/}, commands[0][:tokens][2].value)
    assert_equal({number: 10, unit: "s", raw: "10s"},
                 commands[1][:tokens][2].value)
    assert_equal({pattern: /second/}, commands[1][:tokens][4].value)
    assert_equal({pattern: /third/}, commands[2][:tokens][2].value)
  end

  test "preserves line and column info" do
    result = parse("WaitUntil /ready/\n")

    command = result[0]
    assert_equal 1, command[:line]
    assert_equal 1, command[:column]

    identifier = command[:tokens][0]
    assert_equal 1, identifier.line
    assert_equal 1, identifier.column

    regex = command[:tokens][2]
    assert_equal 1, regex.line
    assert_equal 11, regex.column
  end

  test "preserves line and column info with duration" do
    result = parse("WaitUntil@5s /done/\n")

    command = result[0]
    assert_equal 1, command[:line]
    assert_equal 1, command[:column]

    at_token = command[:tokens][1]
    assert_equal 1, at_token.line
    assert_equal 10, at_token.column

    duration = command[:tokens][2]
    assert_equal 1, duration.line
    assert_equal 11, duration.column

    space = command[:tokens][3]
    assert_equal 1, space.line
    assert_equal 13, space.column
  end

  test "parses WaitUntil inside Group" do
    source = <<~TAPE
      Group build do
        Run "make"
        WaitUntil /Build complete/
        Run "echo done"
      end
    TAPE

    result = parse(source)
    group = result[0]

    assert_equal :group, group[:type]

    commands = group[:children].select do |item|
      item.is_a?(Hash) && item[:type] == :command
    end
    assert_equal 3, commands.length

    # Second command is WaitUntil
    wait_cmd = commands[1]
    assert_equal "WaitUntil", wait_cmd[:tokens][1].value
    assert_equal({pattern: /Build complete/}, wait_cmd[:tokens][3].value)
  end

  test "parses WaitUntil with whitespace in regex" do
    result = parse("WaitUntil /status: complete/\n")

    command = result[0]
    assert_equal({pattern: /status: complete/}, command[:tokens][2].value)
  end

  test "parses WaitUntil with empty regex pattern" do
    result = parse("WaitUntil //\n")

    command = result[0]
    assert_equal({pattern: //}, command[:tokens][2].value)
  end

  test "parses WaitUntil with word boundaries" do
    result = parse('WaitUntil /\bword\b/')

    command = result[0]
    assert_equal({pattern: /\bword\b/}, command[:tokens][2].value)
  end

  test "parses WaitUntil with alternation" do
    result = parse("WaitUntil /ready|complete|done/\n")

    command = result[0]
    assert_equal({pattern: /ready|complete|done/}, command[:tokens][2].value)
  end

  test "parses WaitUntil with quantifiers" do
    result = parse("WaitUntil /test{2,5}/\n")

    command = result[0]
    assert_equal({pattern: /test{2,5}/}, command[:tokens][2].value)
  end

  test "parses WaitUntil with lookahead" do
    result = parse("WaitUntil /foo(?=bar)/\n")

    command = result[0]
    assert_equal({pattern: /foo(?=bar)/}, command[:tokens][2].value)
  end

  test "parses WaitUntil with trailing space before newline" do
    result = parse("WaitUntil /test/  \n")

    command = result[0]
    # Should have: WaitUntil, space, regex, trailing_space
    assert_equal 4, command[:tokens].length
    assert_instance_of DemoTape::Token::TrailingSpace, command[:tokens][3]
  end

  test "fails with invalid regex" do
    error = assert_raises(DemoTape::ParseError) do
      parse("WaitUntil /[derp/\n")
    end

    expected = "Invalid regular expression (premature end of char-class) at " \
               "<unknown>:1:11:\n" \
               "  WaitUntil /[derp/\n" \
               "            ^"

    assert_equal expected, error.message
  end
end
