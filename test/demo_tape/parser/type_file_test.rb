# frozen_string_literal: true

require "test_helper"

class ParserTypeFileTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses TypeFile command" do
    result = parse(%[TypeFile "examples/script.rb"\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "TypeFile", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][1]

    assert_instance_of DemoTape::Token::String, command[:tokens][2]
    assert_equal "examples/script.rb", command[:tokens][2].value
  end

  test "parses TypeFile with different paths" do
    paths = [
      "file.txt",
      "examples/demo.tape",
      "../other/file.rb"
    ]

    paths.each do |path|
      result = parse(%[TypeFile "#{path}"\n])
      command = result[0]

      assert_equal :command, command[:type]
      assert_instance_of DemoTape::Token::String, command[:tokens][2]
      assert_equal path, command[:tokens][2].value
    end
  end
end
