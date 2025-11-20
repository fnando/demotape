# frozen_string_literal: true

require "test_helper"

class ParserIncludeTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses Include command" do
    result = parse(%[Include "examples/demo.tape"\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].length

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Include", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][1]

    assert_instance_of DemoTape::Token::String, command[:tokens][2]
    assert_equal "examples/demo.tape", command[:tokens][2].value
  end

  test "parses Include with different paths" do
    paths = [
      "file.tape",
      "examples/test.tape",
      "../other.tape"
    ]

    paths.each do |path|
      result = parse(%[Include "#{path}"\n])
      command = result[0]

      assert_equal :command, command[:type]
      assert_instance_of DemoTape::Token::String, command[:tokens][2]
      assert_equal path, command[:tokens][2].value
    end
  end
end
