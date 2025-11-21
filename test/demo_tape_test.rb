# frozen_string_literal: true

require "test_helper"

class DemoTapeTest < Minitest::Test
  test "supports escaping quotes in strings" do
    assert_equal %[say "hello"],
                 to_commands(%[Type "say \\"hello\\""]).first.args

    assert_equal "say 'hello'",
                 to_commands("Type 'say \\'hello\\''").first.args
  end

  test "fails to parse unknown command" do
    error = assert_raises(DemoTape::ParseError) do
      to_commands("Reboot")
    end

    expected = [
      %[Unexpected token "Reboot" at <unknown>:1:1:],
      "  Reboot",
      "  ^"
    ].join("\n")

    assert_equal expected, error.message
  end

  test "fails if commands receive duration when they don't expect it" do
    error = assert_raises(DemoTape::ParseError) do
      to_commands("Set@10ms margin 10")
    end

    expected = [
      %[Unexpected token "@" at <unknown>:1:4:],
      "  Set@10ms margin 10",
      "     ^"
    ].join("\n")

    assert_equal expected, error.message
  end

  test "fails if command has invalid duration unit" do
    error = assert_raises(DemoTape::ParseError) do
      to_commands("Type@10ns 'hello'")
    end

    expected = [
      %[Invalid unit "ns" in duration at <unknown>:1:6:],
      "  Type@10ns 'hello'",
      "       ^"
    ].join("\n")

    assert_equal expected, error.message
  end

  test "fails if Sleep has invalid duration unit" do
    error = assert_raises(DemoTape::ParseError) do
      to_commands("Sleep 10ns")
    end

    expected = [
      %[Invalid unit "ns" in duration at <unknown>:1:7:],
      "  Sleep 10ns",
      "        ^"
    ].join("\n")

    assert_equal expected, error.message
  end

  test "fails with key combo on a command that doesn't support one" do
    error = assert_raises(DemoTape::ParseError) do
      to_commands("Wait+Alt")
    end

    expected = [
      %[Unexpected token "+" at <unknown>:1:5:],
      "  Wait+Alt",
      "      ^"
    ].join("\n")

    assert_equal expected, error.message
  end

  test "fails with key combo that also lists a command" do
    error = assert_raises(DemoTape::ParseError) do
      to_commands("Ctrl+Alt+Wait")
    end

    expected = [
      %[Unexpected token "Wait" at <unknown>:1:10:],
      "  Ctrl+Alt+Wait",
      "           ^"
    ].join("\n")

    assert_equal expected, error.message
  end

  test "fails with key combo with spaces" do
    error = assert_raises(DemoTape::ParseError) do
      to_commands("Ctrl + Shift + D")
    end

    expected = [
      %[Invalid spacing around '+' in key combo at <unknown>:1:6:],
      "  Ctrl + Shift + D",
      "       ^"
    ].join("\n")

    assert_equal expected, error.message
  end

  test "accepts valid key combos" do
    assert_equal %w[L Alt Delete],
                 to_commands("Ctrl+L+Alt+Delete")[0].options[:keys]
  end

  test "accepts single keys with press count" do
    assert_equal 3, to_commands("Backspace 3")[0].options[:count]
  end

  test "accepts key combo with press count" do
    assert_equal 3, to_commands("Ctrl+Left 3")[0].options[:count]
  end

  test "fails if commands receive count when they don't expect it" do
    error = assert_raises(DemoTape::ParseError) do
      to_commands("Type 'hello'    2")
    end

    expected = [
      %[Unexpected token "2" at <unknown>:1:17:],
      "  Type 'hello'    2",
      "                  ^"
    ].join("\n")

    assert_equal expected, error.message
  end

  test "fails if commands receive any trailing token" do
    error = assert_raises(DemoTape::ParseError) do
      to_commands("Type 'hello'  a  @123ms")
    end

    expected = [
      %[Unexpected token "a" at <unknown>:1:15:],
      "  Type 'hello'  a  @123ms",
      "                ^"
    ].join("\n")

    assert_equal expected, error.message
  end

  test "parses command with comments" do
    commands = to_commands(<<~TAPE)
      # This is a comment
      Type 'hello'
      # One more comment
      Wait 500ms
      # And another one
    TAPE

    assert_equal 2, commands.size
    assert_equal "Type", commands[0].type
    assert_equal "Wait", commands[1].type
  end

  test "fails with invalid nested properties that are not recognized" do
    error = assert_raises(DemoTape::ParseError) do
      to_commands(%[Set foo.invalid "#222222"])
    end

    expected = [
      %[Unexpected token "foo.invalid" at <unknown>:1:5:],
      %[  Set foo.invalid "#222222"],
      %[      ^]
    ].join("\n")

    assert_equal expected, error.message
  end
end
