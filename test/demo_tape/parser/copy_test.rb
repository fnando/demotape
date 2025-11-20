# frozen_string_literal: true

require "test_helper"

class ParserCopyTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses Copy command" do
    result = parse(%[Copy "https://github.com/fnando/demotape"\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].length

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Copy", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][1]

    assert_instance_of DemoTape::Token::String, command[:tokens][2]
    assert_equal "https://github.com/fnando/demotape", command[:tokens][2].value
  end

  test "parses Copy with text" do
    result = parse(%[Copy "some text to copy"\n])

    command = result[0]
    assert_equal :command, command[:type]

    assert_instance_of DemoTape::Token::String, command[:tokens][2]
    assert_equal "some text to copy", command[:tokens][2].value
  end
end
