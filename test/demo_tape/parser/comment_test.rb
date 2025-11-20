# frozen_string_literal: true

require "test_helper"

class ParserCommentTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses comment at document root" do
    source = "# This is a comment\n"
    result = parse(source)

    # Parser returns document-level tokens
    # At document root we have: Comments, Commands (as contexts),
    # Groups (as contexts), Newlines, Spaces
    assert_equal 2, result.size

    # First is the comment token
    assert_instance_of DemoTape::Token::Comment, result[0]
    assert_equal "# This is a comment", result[0].value

    # Second is the newline token
    assert_instance_of DemoTape::Token::Newline, result[1]
    assert_equal "\n", result[1].value
  end

  test "parses comment with leading space" do
    source = "  # Indented comment\n"
    result = parse(source)

    # Document root has: LEADING_SPACE (token), COMMENT (token), NEWLINE (token)
    assert_equal 3, result.size

    assert_instance_of DemoTape::Token::LeadingSpace, result[0]
    assert_equal "  ", result[0].value

    assert_instance_of DemoTape::Token::Comment, result[1]
    assert_equal "# Indented comment", result[1].value

    assert_instance_of DemoTape::Token::Newline, result[2]
    assert_equal "\n", result[2].value
  end

  test "parses mixed comments and commands" do
    source = <<~TAPE
      # Setup phase
      Type "hello"
    TAPE

    result = parse(source)

    # Should have:
    # COMMENT (token), NEWLINE (token), COMMAND (context), NEWLINE (token)
    assert_equal 4, result.size

    assert_instance_of DemoTape::Token::Comment, result[0]
    assert_instance_of DemoTape::Token::Newline, result[1]

    # Command is a context (hash) containing its tokens
    assert_kind_of Hash, result[2]
    assert_equal :command, result[2][:type]
    assert_instance_of Array, result[2][:tokens]

    assert_instance_of DemoTape::Token::Newline, result[3]
  end
end
