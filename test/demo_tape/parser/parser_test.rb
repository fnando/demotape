# frozen_string_literal: true

require "test_helper"

class ParserTest < Minitest::Test
  test "parses syntax file" do
    DemoTape::Parser.new.parse(File.read("test/fixtures/syntax.tape"))
  end

  test "fails with invalid commands" do
    error = assert_raises(DemoTape::ParseError) do
      to_commands("FlyAway")
    end

    expected = [
      %[Unexpected token "FlyAway" at <unknown>:1:1:],
      "  FlyAway",
      "  ^"
    ].join("\n")

    assert_equal expected, error.message
  end
end
