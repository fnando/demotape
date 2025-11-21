# frozen_string_literal: true

require "test_helper"

class ThemeTest < Minitest::Test
  test "parses theme name" do
    command = to_commands(%[Set theme "default_dark"]).first

    assert_equal "Set", command.type
    assert_equal "theme", command.options[:option]
    assert_equal "default_dark", command.args
  end

  test "parses theme color" do
    command = to_commands(%[Set theme.background "#222222"]).first

    assert_equal "Set", command.type
    assert_equal "theme", command.options[:option]
    assert_equal "background", command.options[:property]
    assert_equal "#222222", command.args
  end

  test "fails with invalid theme property" do
    error = assert_raises(DemoTape::ParseError) do
      to_commands(%[Set theme.invalid "#222222"])
    end

    expected = [
      %[Invalid theme property at <unknown>:1:11:],
      %[  Set theme.invalid "#222222"],
      %[            ^]
    ].join("\n")

    assert_equal expected, error.message
  end
end
