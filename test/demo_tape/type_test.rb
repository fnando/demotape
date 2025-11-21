# frozen_string_literal: true

require "test_helper"

class TypeTest < Minitest::Test
  test "parses Type using single quotes" do
    commands = to_commands("Type 'ls -1'")

    assert_equal 1, commands.size
    assert_equal "Type", commands[0].type
    assert_equal "ls -1", commands[0].args
    assert_empty commands[0].options
  end

  test "parses Type using double quotes" do
    commands = to_commands(%[Type "ls -1"])

    assert_equal 1, commands.size
    assert_equal "Type", commands[0].type
    assert_equal "ls -1", commands[0].args
    assert_empty commands[0].options
  end

  test "parses Type@duration" do
    commands = to_commands(%[Type@30ms "ls -1"])

    assert_equal 1, commands.size
    assert_equal "Type", commands[0].type
    assert_equal "ls -1", commands[0].args
    assert_equal({duration: 0.03}, commands[0].options)
  end
end
