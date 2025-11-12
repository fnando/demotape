# frozen_string_literal: true

require "test_helper"

class DurationTest < Minitest::Test
  test "parses time without leading zero" do
    assert_in_delta(0.25, DemoTape::Duration.parse(".25s"))
    assert_in_delta(15, DemoTape::Duration.parse(".25m"))
  end

  test "parses time without unit" do
    assert_in_delta(1, DemoTape::Duration.parse("1"))
    assert_in_delta(25, DemoTape::Duration.parse("25"))
  end

  test "parses milliseconds" do
    assert_in_delta(0.5, DemoTape::Duration.parse("500ms"))
    assert_in_delta(1.0, DemoTape::Duration.parse("1000ms"))
  end

  test "parses seconds" do
    assert_in_delta(30.0, DemoTape::Duration.parse("30s"))
    assert_in_delta(60.0, DemoTape::Duration.parse("60s"))
    assert_in_delta(5.0, DemoTape::Duration.parse("5"))
  end

  test "parses minutes" do
    assert_in_delta(60.0, DemoTape::Duration.parse("1m"))
    assert_in_delta(120.0, DemoTape::Duration.parse("2m"))
    assert_in_delta(600.0, DemoTape::Duration.parse("10m"))
  end

  test "parses hours" do
    assert_in_delta(3600.0, DemoTape::Duration.parse("1h"))
    assert_in_delta(7200.0, DemoTape::Duration.parse("2h"))
    assert_in_delta(36_000.0, DemoTape::Duration.parse("10h"))
  end

  test "fails with invalid unit" do
    error = assert_raises(ArgumentError) do
      DemoTape::Duration.parse("10ns")
    end

    assert_equal %[Unknown time unit: "ns"], error.message
  end
end
