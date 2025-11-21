# frozen_string_literal: true

require "test_helper"

class WaitTest < Minitest::Test
  test "parses wait" do
    command = to_commands("Wait 2s").first

    assert_equal "Wait", command.type
    assert_equal 2, command.options[:duration]
  end

  test "parses sleep" do
    command = to_commands("Sleep 2s").first

    assert_equal "Sleep", command.type
    assert_equal 2, command.options[:duration]
  end

  test "parses wait without unit" do
    command = to_commands("Wait 2").first

    assert_equal "Wait", command.type
    assert_equal 2, command.options[:duration]
  end

  test "parses sleep without unit" do
    command = to_commands("Sleep 2").first

    assert_equal "Sleep", command.type
    assert_equal 2, command.options[:duration]
  end
end
