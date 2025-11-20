# frozen_string_literal: true

require "test_helper"

class ParserPauseTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses Pause command" do
    result = parse(%[Pause\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 1, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Pause", command[:tokens][0].value
  end

  test "parses Pause with leading space" do
    result = parse(%[  Pause\n])

    assert_equal 2, result.size

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 2, command[:tokens].size
    assert_instance_of DemoTape::Token::LeadingSpace, command[:tokens][0]
    assert_instance_of DemoTape::Token::Identifier, command[:tokens][1]
    assert_equal "Pause", command[:tokens][1].value

    assert_instance_of DemoTape::Token::Newline, result[1]
  end
end
