# frozen_string_literal: true

require "test_helper"

class FormatterTest < Minitest::Test
  Dir["./test/fixtures/formatter/*.input.tape"].each do |input_path|
    name = File.basename(input_path, ".input.tape").inspect
    test "formats #{name} correctly" do
      input = File.read(input_path)
      expected = File.read(input_path.sub(".input.tape", ".expected.tape"))
      actual = DemoTape::Formatter.new(input).call

      assert_equal expected, actual
    end
  end

  test "formats Sleep" do
    assert_equal "Sleep 1s\n", format_tape("Sleep 1")
    assert_equal "Sleep 1s\n", format_tape("Sleep      1")
    assert_equal "Sleep 1s\n", format_tape("Sleep      1     ")
    assert_equal "Sleep 1s\n", format_tape("    Sleep      1     ")
  end

  test "formats Wait" do
    assert_equal "Wait 1s\n", format_tape("Wait 1")
    assert_equal "Wait 1s\n", format_tape("Wait      1")
    assert_equal "Wait 1s\n", format_tape("Wait      1     ")
    assert_equal "Wait 1s\n", format_tape("    Wait      1     ")
  end

  test "formats WaitUntil" do
    assert_equal "WaitUntil /[a-z]+/\n", format_tape("WaitUntil     /[a-z]+/")
    assert_equal "WaitUntil /[a-z]+/\n", format_tape("WaitUntil   /[a-z]+/  ")
  end

  def format_tape(tape)
    DemoTape::Formatter.new(tape).call
  end
end
