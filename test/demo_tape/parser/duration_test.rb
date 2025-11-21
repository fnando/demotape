# frozen_string_literal: true

require "test_helper"

class ParseDurationTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses milliseconds" do
    result = parse(%[Sleep 100ms\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Sleep", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][1]

    assert_instance_of DemoTape::Token::Duration, command[:tokens][2]
    assert_equal 100, command[:tokens][2].value[:number]
    assert_equal "ms", command[:tokens][2].value[:unit]
  end

  test "parses seconds" do
    result = parse(%[Sleep 200s\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Sleep", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][1]

    assert_instance_of DemoTape::Token::Duration, command[:tokens][2]
    assert_equal 200, command[:tokens][2].value[:number]
    assert_equal "s", command[:tokens][2].value[:unit]
  end

  test "parses minutes" do
    result = parse(%[Sleep 1m\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Sleep", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][1]

    assert_instance_of DemoTape::Token::Duration, command[:tokens][2]
    assert_equal 1, command[:tokens][2].value[:number]
    assert_equal "m", command[:tokens][2].value[:unit]
  end

  test "parses hour" do
    result = parse(%[Sleep 24h\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Sleep", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][1]

    assert_instance_of DemoTape::Token::Duration, command[:tokens][2]
    assert_equal 24, command[:tokens][2].value[:number]
    assert_equal "h", command[:tokens][2].value[:unit]
  end
end
