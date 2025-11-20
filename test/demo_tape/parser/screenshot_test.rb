# frozen_string_literal: true

require "test_helper"

class ParserScreenshotTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses Screenshot command" do
    result = parse(%[Screenshot "output.png"\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Screenshot", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][1]

    assert_instance_of DemoTape::Token::String, command[:tokens][2]
    assert_equal "output.png", command[:tokens][2].value
  end

  test "parses Screenshot with path" do
    result = parse(%[Screenshot "examples/screenshot.png"\n])

    command = result[0]
    assert_equal :command, command[:type]

    assert_instance_of DemoTape::Token::String, command[:tokens][2]
    assert_equal "examples/screenshot.png", command[:tokens][2].value
  end
end
