# frozen_string_literal: true

require "test_helper"

class WaitUntilTest < Minitest::Test
  test "accepts WaitUntil with regex" do
    cmd = to_commands("WaitUntil /line 10/")[0]

    assert_equal "WaitUntil", cmd.type
    assert_equal({pattern: /line 10/}, cmd.args)
  end

  test "accepts WaitUntil with duration" do
    cmd = to_commands("WaitUntil@30s /Done!/")[0]

    assert_equal "WaitUntil", cmd.type
    assert_equal({pattern: /Done!/}, cmd.args)
    assert_in_delta(30.0, cmd.options[:duration])
  end
end
