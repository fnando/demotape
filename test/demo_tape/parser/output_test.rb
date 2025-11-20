# frozen_string_literal: true

require "test_helper"

class ParserOutputTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses Output command" do
    result = parse(%[Output "output.mp4"\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Output", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][1]

    assert_instance_of DemoTape::Token::String, command[:tokens][2]
    assert_equal "output.mp4", command[:tokens][2].value
  end

  test "parses Output with different formats" do
    formats = [
      "output.mp4",
      "output.gif",
      "output.webm",
      "examples/test.mp4"
    ]

    formats.each do |format|
      result = parse(%[Output "#{format}"\n])
      command = result[0]

      assert_equal :command, command[:type]
      assert_instance_of DemoTape::Token::String, command[:tokens][2]
      assert_equal format, command[:tokens][2].value
    end
  end
end
