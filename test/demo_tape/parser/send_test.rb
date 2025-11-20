# frozen_string_literal: true

require "test_helper"

class ParserSendTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses Send command" do
    result = parse(%[Send "ls -la\\n"\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Send", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][1]

    assert_instance_of DemoTape::Token::String, command[:tokens][2]
    # \n should be processed to actual newline character
    assert_equal "ls -la\n", command[:tokens][2].value
  end

  test "parses Send with escape sequences" do
    result = parse(%[Send "echo hello\\n"\n])

    command = result[0]
    assert_equal :command, command[:type]

    assert_instance_of DemoTape::Token::String, command[:tokens][2]
    # \n should be processed to actual newline character
    assert_equal "echo hello\n", command[:tokens][2].value
  end

  test "parses Send with escaped backslash" do
    result = parse(%[Send "line1\\\\nline2"\n])

    command = result[0]
    assert_equal :command, command[:type]

    assert_instance_of DemoTape::Token::String, command[:tokens][2]
    # \\n should become literal backslash + n (not newline)
    assert_equal "line1\\nline2", command[:tokens][2].value
  end

  test "parses Send with backslash and newline" do
    result = parse(%[Send "path\\\\\\n"\n])

    command = result[0]
    assert_equal :command, command[:type]

    assert_instance_of DemoTape::Token::String, command[:tokens][2]
    # \\\n should become backslash + newline
    assert_equal "path\\\n", command[:tokens][2].value
  end
end
