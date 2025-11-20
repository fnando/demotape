# frozen_string_literal: true

require "test_helper"

class GroupTest < Minitest::Test
  test "parses grouped commands" do
    tape = <<~TAPE
      Group setup do
        Run "echo 'Hello there!'"
        Type "echo 'Bye now!'"
        Enter
      end

      setup
    TAPE

    DemoTape::Parser.new.parse(tape) => [command, *]
    command.children => [run_cmd, type_cmd, enter_cmd]

    assert command.meta?
    assert command.group?
    assert_equal 3, command.children.size

    assert_equal "Run", run_cmd.type
    assert_equal %[echo 'Hello there!'], run_cmd.args
    refute run_cmd.group?

    assert_equal "Type", type_cmd.type
    assert_equal %[echo 'Bye now!'], type_cmd.args
    refute type_cmd.group?

    assert_equal "Enter", enter_cmd.type
    refute enter_cmd.group?
  end

  test "raises error with nested groups" do
    tape = <<~TAPE
      Group setup do
        Group another do
          Run "echo 'Hello there!'"
          Run "echo 'Bye now!'"
        end
      end
    TAPE

    error = assert_raises(DemoTape::ParseError) do
      DemoTape::Parser.new.parse(tape)
    end

    expected = "Nested groups are not allowed at <unknown>:2:3:\n" \
               "  Group another do\n" \
               "  ^"

    assert_equal(expected, error.message)
  end

  test "raises error with blocks in non-group commands" do
    tape = <<~TAPE
      Run "echo 'Hello there!'" do
        Run "echo 'This should fail!'"
      end
    TAPE

    expected = "Unexpected token \"DO\" at <unknown>:1:27:\n  " \
               "Run \"echo 'Hello there!'\" do\n" \
               "                            ^"

    error = assert_raises(DemoTape::ParseError) do
      DemoTape::Parser.new.parse(tape)
    end

    assert_equal expected, error.message
  end
end
