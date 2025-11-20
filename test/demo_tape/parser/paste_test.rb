# frozen_string_literal: true

require "test_helper"

class ParserPasteTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses Paste command" do
    result = parse(%[Paste\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 1, command[:tokens].length

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Paste", command[:tokens][0].value
  end

  test "parses Paste with leading space" do
    result = parse(%[  Paste\n])

    assert_equal 2, result.length

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 2, command[:tokens].length
    assert_instance_of DemoTape::Token::LeadingSpace, command[:tokens][0]
    assert_instance_of DemoTape::Token::Identifier, command[:tokens][1]
    assert_equal "Paste", command[:tokens][1].value

    assert_instance_of DemoTape::Token::Newline, result[1]
  end
end
