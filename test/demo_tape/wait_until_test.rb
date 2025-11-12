# frozen_string_literal: true

require "test_helper"

class WaitUntilTest < Minitest::Test
  test "accepts WaitUntil with regex" do
    cmd = parse("WaitUntil /line 10/")[0]

    assert_equal "WaitUntil", cmd.type
    assert_equal "line 10", cmd.args
  end

  test "accepts WaitUntil with timeout" do
    cmd = parse("WaitUntil@30s /Done!/")[0]

    assert_equal "WaitUntil", cmd.type
    assert_equal "Done!", cmd.args
    assert_equal "30s", cmd.options[:timeout]
  end

  test "fails with invalid regex" do
    error = assert_raises(DemoTape::ParseError) do
      parse("WaitUntil /[derp/")
    end

    expected = [
      "Invalid regex: premature end of char-class: /[derp/ at <unknown>:1:11:",
      "  WaitUntil /[derp/",
      "            ^"
    ].join("\n")

    assert_equal expected, error.message
  end
end
