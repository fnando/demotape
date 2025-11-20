# frozen_string_literal: true

require "test_helper"

class DemoTapeTest < Minitest::Test
  test "supports escaping quotes in strings" do
    assert_equal %[say "hello"],
                 parse(%[Type "say \\"hello\\""]).first.args

    assert_equal "say 'hello'",
                 parse("Type 'say \\'hello\\''").first.args
  end

  test "fails to parse unknown command" do
    error = assert_raises(DemoTape::ParseError) do
      parse("Reboot")
    end

    expected = [
      %[Unknown command: "Reboot" at <unknown>:1:1:],
      "  Reboot",
      "  ^"
    ].join("\n")

    assert_equal expected, error.message
  end

  test "fails if commands receive duration when they don't expect it" do
    error = assert_raises(DemoTape::ParseError) do
      parse("Send@10ms")
    end

    expected = [
      %[Command "Send" does not accept a duration option at <unknown>:1:5:],
      "  Send@10ms",
      "      ^"
    ].join("\n")

    assert_equal expected, error.message
  end

  test "fails if command has invalid duration unit" do
    error = assert_raises(DemoTape::ParseError) do
      parse("Type@10ns 'hello'")
    end

    expected = [
      %[Invalid time unit: "ns" at <unknown>:1:8:],
      "  Type@10ns 'hello'",
      "         ^"
    ].join("\n")

    assert_equal expected, error.message
  end

  test "fails with key combo on a command that doesn't support one" do
    error = assert_raises(DemoTape::ParseError) do
      parse("Wait+Alt")
    end

    expected = [
      %[Command "Wait" doesn't support key combos at <unknown>:1:6:],
      "  Wait+Alt",
      "       ^"
    ].join("\n")

    assert_equal expected, error.message
  end

  test "fails with key combo that also lists a command" do
    error = assert_raises(DemoTape::ParseError) do
      parse("Ctrl+Alt+Wait")
    end

    expected = [
      %[Command "Wait" doesn't support key combos at <unknown>:1:10:],
      "  Ctrl+Alt+Wait",
      "           ^"
    ].join("\n")

    assert_equal expected, error.message
  end

  test "fails with key combo with spaces" do
    error = assert_raises(DemoTape::ParseError) do
      parse("Ctrl + Shift + D")
    end

    expected = [
      %[Unexpected token "SPACE" at <unknown>:1:5:],
      "  Ctrl + Shift + D",
      "      ^"
    ].join("\n")

    assert_equal expected, error.message
  end

  test "accepts valid key combos" do
    assert_equal %w[L Alt Delete],
                 parse("Ctrl+L+Alt+Delete")[0].options[:keys]
  end

  test "accepts single keys with press count" do
    assert_equal 3, parse("Backspace 3")[0].options[:count]
  end

  test "accepts key combo with press count" do
    assert_equal 3, parse("Ctrl+Left 3")[0].options[:count]
  end

  test "fails if commands receive count when they don't expect it" do
    error = assert_raises(DemoTape::ParseError) do
      parse("Type 'hello' 2")
    end

    expected = [
      %[Unexpected token "NUMBER" at <unknown>:1:14:],
      "  Type 'hello' 2",
      "               ^"
    ].join("\n")

    assert_equal expected, error.message
  end

  test "parses command with comments" do
    commands = parse(<<~TAPE)
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
      parse(%[Set foo.invalid "#222222"])
    end

    expected = [
      %[Unexpected attribute "foo.invalid" at <unknown>:1:5:],
      %[  Set foo.invalid "#222222"],
      %[      ^]
    ].join("\n")

    assert_equal expected, error.message
  end
end
