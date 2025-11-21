# frozen_string_literal: true

require "test_helper"

class ParserSleepTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses Sleep with duration" do
    result = parse(%[Sleep 2s\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Sleep", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][1]

    assert_instance_of DemoTape::Token::Duration, command[:tokens][2]
    assert_equal 2, command[:tokens][2].value[:number]
    assert_equal "s", command[:tokens][2].value[:unit]
  end

  test "parses Sleep without unit (plain number)" do
    result = parse(%[Sleep 3\n])

    command = result[0]
    assert_equal :command, command[:type]

    assert_instance_of DemoTape::Token::Number, command[:tokens][2]
    assert_equal 3, command[:tokens][2].value
  end
end
