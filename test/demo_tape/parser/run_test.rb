# frozen_string_literal: true

require "test_helper"

class ParserRunTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses Run command" do
    result = parse(%[Run "ls -la"\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Run", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][1]

    assert_instance_of DemoTape::Token::String, command[:tokens][2]
    assert_equal "ls -la", command[:tokens][2].value
  end

  test "parses Run with duration" do
    result = parse(%[Run@100ms "echo hello"\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 5, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Run", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Operator, command[:tokens][1]
    assert_equal "@", command[:tokens][1].value

    assert_instance_of DemoTape::Token::Duration, command[:tokens][2]
    assert_equal({number: 100, unit: "ms", raw: "100ms"}, command[:tokens][2].value)

    assert_instance_of DemoTape::Token::Space, command[:tokens][3]

    assert_instance_of DemoTape::Token::String, command[:tokens][4]
    assert_equal "echo hello", command[:tokens][4].value
  end

  test "parses Run with duration variations" do
    [
      [%[Run@100ms "cmd"\n], 100, "ms", "100ms"],
      [%[Run@1s "cmd"\n], 1, "s", "1s"],
      [%[Run@500ms "cmd"\n], 500, "ms", "500ms"]
    ].each do |source, expected_num, expected_unit, expected_raw|
      result = parse(source)
      command = result[0]

      assert_instance_of DemoTape::Token::Duration, command[:tokens][2]
      assert_equal({number: expected_num, unit: expected_unit, raw: expected_raw}, command[:tokens][2].value)
    end
  end
end
