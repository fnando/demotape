# frozen_string_literal: true

require "test_helper"

class ParserResumeTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses Resume command" do
    result = parse(%[Resume\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 1, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Resume", command[:tokens][0].value
  end

  test "parses Resume with leading space" do
    result = parse(%[  Resume\n])

    assert_equal 2, result.size

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 2, command[:tokens].size
    assert_instance_of DemoTape::Token::LeadingSpace, command[:tokens][0]
    assert_instance_of DemoTape::Token::Identifier, command[:tokens][1]
    assert_equal "Resume", command[:tokens][1].value

    assert_instance_of DemoTape::Token::Newline, result[1]
  end
end
