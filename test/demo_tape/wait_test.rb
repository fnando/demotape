# frozen_string_literal: true

require "test_helper"

class WaitTest < Minitest::Test
  test "parses wait" do
    command = parse("Wait 2s").first

    assert_equal "Wait", command.type
    assert_equal "2s", command.args
  end

  test "parses sleep" do
    command = parse("Sleep 2s").first

    assert_equal "Sleep", command.type
    assert_equal "2s", command.args
  end

  test "parses wait without unit" do
    command = parse("Wait 2").first

    assert_equal "Wait", command.type
    assert_equal "2s", command.args
  end

  test "parses sleep without unit" do
    command = parse("Sleep 2").first

    assert_equal "Sleep", command.type
    assert_equal "2s", command.args
  end
end
