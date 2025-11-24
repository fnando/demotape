# frozen_string_literal: true

require "test_helper"

class ParserMultilineString < Minitest::Test
  def parse_and_convert(source)
    parser = DemoTape::Parser.new
    tree = parser.parse(source)
    parser.to_commands(tree)
  end

  test "parses send with multiline strings" do
    source = <<~DEMOTAPE
      Send """
      echo hello
      echo goodbye
      """
    DEMOTAPE

    result = parse_and_convert(source)

    assert_equal 1, result.size

    command = result.first
    assert_equal "echo hello\necho goodbye\n", command.args
  end

  test "honours existing newline" do
    source = <<~DEMOTAPE
      Send """
      echo hello
      echo goodbye

      """
    DEMOTAPE

    result = parse_and_convert(source)

    assert_equal 1, result.size

    command = result.first
    assert_equal "echo hello\necho goodbye\n", command.args
  end
end
