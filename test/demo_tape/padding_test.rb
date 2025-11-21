# frozen_string_literal: true

require "test_helper"

class PaddingTest < Minitest::Test
  test "parses padding" do
    command = to_commands("Set padding 10").first

    assert_equal "Set", command.type
    assert_equal "padding", command.options[:option]
    assert_equal [10, 10, 10, 10], command.args

    command = to_commands("Set padding 10, 20").first

    assert_equal "Set", command.type
    assert_equal "padding", command.options[:option]
    assert_equal [10, 20, 10, 20], command.args

    command = to_commands("Set padding 10, 20, 30").first

    assert_equal "Set", command.type
    assert_equal "padding", command.options[:option]
    assert_equal [10, 20, 30, 10], command.args

    command = to_commands("Set padding 10, 20, 30, 40").first

    assert_equal "Set", command.type
    assert_equal "padding", command.options[:option]
    assert_equal [10, 20, 30, 40], command.args
  end
end
