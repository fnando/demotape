# frozen_string_literal: true

require "test_helper"

class ParserTypeTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses Type with double quotes" do
    result = parse(%[Type "echo 'Hello, World!'"\n])

    assert_equal 2, result.size

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].size
    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Type", command[:tokens][0].value
    assert_instance_of DemoTape::Token::Space, command[:tokens][1]
    assert_instance_of DemoTape::Token::String, command[:tokens][2]
    assert_equal "echo 'Hello, World!'", command[:tokens][2].value

    assert_instance_of DemoTape::Token::Newline, result[1]
  end

  test "parses Type with single quotes" do
    result = parse(%[Type 'ls -la'\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].size
    assert_equal "Type", command[:tokens][0].value
    assert_equal "ls -la", command[:tokens][2].value
  end

  test "parses Type with duration" do
    result = parse(%[Type@50ms "fast typing"\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 5, command[:tokens].size

    assert_equal "Type", command[:tokens][0].value
    assert_instance_of DemoTape::Token::Operator, command[:tokens][1]
    assert_equal "@", command[:tokens][1].value
    assert_instance_of DemoTape::Token::Duration, command[:tokens][2]
    assert_equal 50, command[:tokens][2].value[:number]
    assert_equal "ms", command[:tokens][2].value[:unit]
    assert_instance_of DemoTape::Token::Space, command[:tokens][3]
    assert_instance_of DemoTape::Token::String, command[:tokens][4]
    assert_equal "fast typing", command[:tokens][4].value
  end

  test "parses Type with leading space" do
    result = parse(%[  Type "indented"\n])

    assert_equal 2, result.size

    command = result[0]
    assert_equal 4, command[:tokens].size
    assert_instance_of DemoTape::Token::LeadingSpace, command[:tokens][0]
    assert_equal "  ", command[:tokens][0].value
    assert_equal "Type", command[:tokens][1].value
    assert_equal "indented", command[:tokens][3].value
  end

  test "parses Type with escaped characters" do
    result = parse(%[Type "echo \\"Hello\\""\n])

    command = result[0]
    assert_equal %[echo "Hello"], command[:tokens][2].value
  end

  test "parses Type with empty string" do
    result = parse(%[Type ""\n])

    command = result[0]
    assert_equal "", command[:tokens][2].value
  end

  test "parses Type with special characters" do
    result = parse(%[Type "!@#$%^&*()"\n])

    command = result[0]
    assert_equal "!@#$%^&*()", command[:tokens][2].value
  end

  test "parses Type with unicode" do
    result = parse(%[Type "Hello 世界 🌍"\n])

    command = result[0]
    assert_equal "Hello 世界 🌍", command[:tokens][2].value
  end

  test "parses Type with newline characters in string" do
    result = parse(%[Type "line1\\nline2"\n])

    command = result[0]
    assert_equal "line1\nline2", command[:tokens][2].value
  end

  test "parses multiple Type commands" do
    result = parse(%[Type "first"\nType "second"\nType "third"\n])

    commands = result.select {|item| item.is_a?(Hash) }
    assert_equal 3, commands.size
    assert_equal "first", commands[0][:tokens][2].value
    assert_equal "second", commands[1][:tokens][2].value
    assert_equal "third", commands[2][:tokens][2].value
  end

  test "parses Type with duration variations" do
    [
      [%[Type@100ms "text"\n], 100, "ms"],
      [%[Type@1s "text"\n], 1, "s"],
      [%[Type@500ms "text"\n], 500, "ms"],
      [%[Type@2s "text"\n], 2, "s"]
    ].each do |source, expected_number, expected_unit|
      result = parse(source)
      command = result[0]
      duration_token = command[:tokens].find {|t| t.is_a?(DemoTape::Token::Duration) }
      assert_equal expected_number, duration_token.value[:number],
                   "Failed number for: #{source}"
      assert_equal expected_unit, duration_token.value[:unit], "Failed unit for: #{source}"
    end
  end

  test "preserves line and column info" do
    result = parse(%[Type "hello"\n])

    command = result[0]
    assert_equal 1, command[:line]
    assert_equal 1, command[:column]

    first_token = command[:tokens][0]
    assert_equal 1, first_token.line
    assert_equal 1, first_token.column
  end

  test "preserves line and column info with leading space" do
    result = parse(%[  Type "hello"\n])

    command = result[0]
    assert_equal 1, command[:line]
    assert_equal 1, command[:column]

    first_token = command[:tokens][0]
    assert_equal 1, first_token.line
    assert_equal 1, first_token.column

    type_token = command[:tokens][1]
    assert_equal 1, type_token.line
    assert_equal 3, type_token.column
  end

  test "parses Type with trailing space" do
    result = parse(%[Type "hello"  \n])

    command = result[0]
    assert_equal 4, command[:tokens].size
    assert_instance_of DemoTape::Token::TrailingSpace, command[:tokens][3]
    assert_equal "  ", command[:tokens][3].value
  end

  test "handles multiline strings with triple quotes" do
    source = <<~TAPE
      Type """
      line 1
      line 2
      """
    TAPE

    result = parse(source)
    command = result[0]

    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].size

    type_token = command[:tokens][0]
    assert_instance_of DemoTape::Token::Identifier, type_token
    assert_equal "Type", type_token.value

    space_token = command[:tokens][1]
    assert_instance_of DemoTape::Token::Space, space_token

    string_token = command[:tokens][2]
    assert_instance_of DemoTape::Token::String, string_token
    assert_equal "line 1\nline 2", string_token.value
    assert_equal 1, string_token.line
    assert_equal 6, string_token.column
  end

  test "handles multiline strings with various quote styles" do
    result1 = parse("Type 'single'\n")
    assert_equal "single", result1[0][:tokens][2].value

    result2 = parse(%[Type "double"\n])
    assert_equal "double", result2[0][:tokens][2].value

    result3 = parse(%[Type """\nmulti\n"""\n])
    assert_equal "multi", result3[0][:tokens][2].value
  end
end
