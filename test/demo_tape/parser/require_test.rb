# frozen_string_literal: true

require "test_helper"

class ParserRequireTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses Require command" do
    result = parse(%[Require "vim"\n])

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Require", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][1]

    assert_instance_of DemoTape::Token::String, command[:tokens][2]
    assert_equal "vim", command[:tokens][2].value
  end

  test "parses Require with different programs" do
    programs = %w[vim bat git node]

    programs.each do |program|
      result = parse(%[Require "#{program}"\n])
      command = result[0]

      assert_equal :command, command[:type]
      assert_instance_of DemoTape::Token::String, command[:tokens][2]
      assert_equal program, command[:tokens][2].value
    end
  end
end
