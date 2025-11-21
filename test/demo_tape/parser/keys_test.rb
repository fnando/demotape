# frozen_string_literal: true

require "test_helper"

class ParserKeysTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses simple key" do
    result = parse("Enter\n")

    assert_equal 2, result.size

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 1, command[:tokens].size
    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Enter", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Newline, result[1]
  end

  test "parses key with count" do
    result = parse("Backspace 5\n")

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Backspace", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][1]

    assert_instance_of DemoTape::Token::Number, command[:tokens][2]
    assert_equal 5, command[:tokens][2].value
  end

  test "parses Ctrl+key combo" do
    result = parse("Ctrl+L\n")

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 3, command[:tokens].size

    assert_equal "Ctrl", command[:tokens][0].value
    assert_instance_of DemoTape::Token::Operator, command[:tokens][1]
    assert_equal "+", command[:tokens][1].value
    assert_equal "L", command[:tokens][2].value
  end

  test "parses triple key combo" do
    result = parse("Ctrl+Shift+T\n")

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 5, command[:tokens].size

    assert_equal "Ctrl", command[:tokens][0].value
    assert_instance_of DemoTape::Token::Operator, command[:tokens][1]
    assert_equal "Shift", command[:tokens][2].value
    assert_instance_of DemoTape::Token::Operator, command[:tokens][3]
    assert_equal "T", command[:tokens][4].value
  end

  test "parses common keys" do
    keys = %w[Enter Escape Tab Backspace Delete Space]

    keys.each do |key|
      result = parse("#{key}\n")
      command = result[0]

      assert_equal :command, command[:type]
      assert_equal 1, command[:tokens].size
      assert_equal key, command[:tokens][0].value
    end
  end

  test "parses arrow keys" do
    arrows = %w[Up Down Left Right]

    arrows.each do |arrow|
      result = parse("#{arrow}\n")
      command = result[0]

      assert_equal :command, command[:type]
      assert_equal arrow, command[:tokens][0].value
    end
  end

  test "parses function keys" do
    result = parse("F12\n")

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal "F12", command[:tokens][0].value
  end

  test "parses Cmd+key combo" do
    result = parse("Cmd+C\n")

    command = result[0]
    assert_equal 3, command[:tokens].size
    assert_equal "Cmd", command[:tokens][0].value
    assert_equal "+", command[:tokens][1].value
    assert_equal "C", command[:tokens][2].value
  end

  test "parses Alt+key combo" do
    result = parse("Alt+Tab\n")

    command = result[0]
    assert_equal 3, command[:tokens].size
    assert_equal "Alt", command[:tokens][0].value
    assert_equal "Tab", command[:tokens][2].value
  end

  test "parses key with leading space" do
    result = parse("  Enter\n")

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 2, command[:tokens].size

    assert_instance_of DemoTape::Token::LeadingSpace, command[:tokens][0]
    assert_equal "  ", command[:tokens][0].value

    assert_equal "Enter", command[:tokens][1].value
  end

  test "parses multiple key commands" do
    source = <<~KEYS
      Ctrl+L
      Enter
      Backspace 3
    KEYS

    result = parse(source)

    # Should have: command, newline, command, newline, command, newline
    commands = result
               .select {|item| item.is_a?(Hash) && item[:type] == :command }
    assert_equal 3, commands.size

    assert_equal "Ctrl", commands[0][:tokens][0].value
    assert_equal "Enter", commands[1][:tokens][0].value
    assert_equal "Backspace", commands[2][:tokens][0].value
    assert_equal 3, commands[2][:tokens][2].value
  end

  test "preserves line and column info for keys" do
    result = parse("Ctrl+C\n")

    command = result[0]
    assert_equal 1, command[:line]
    assert_equal 1, command[:column]

    first_token = command[:tokens][0]
    assert_equal 1, first_token.line
    assert_equal 1, first_token.column

    plus_token = command[:tokens][1]
    assert_equal 1, plus_token.line
    assert_equal 5, plus_token.column

    last_token = command[:tokens][2]
    assert_equal 1, last_token.line
    assert_equal 6, last_token.column
  end

  test "fails when key combo has spaces around plus sign" do
    error = assert_raises(DemoTape::ParseError) do
      parse("Ctrl + C\n")
    end

    expected = "Invalid spacing around '+' in key combo at <unknown>:1:6:\n" \
               "  Ctrl + C\n" \
               "       ^"

    assert_equal expected, error.message
  end

  test "parses Home and End keys" do
    home_result = parse("Home\n")
    end_result = parse("End\n")

    assert_equal "Home", home_result[0][:tokens][0].value
    assert_equal "End", end_result[0][:tokens][0].value
  end

  test "parses PageUp and PageDown" do
    pageup = parse("PageUp\n")
    pagedown = parse("PageDown\n")

    assert_equal "PageUp", pageup[0][:tokens][0].value
    assert_equal "PageDown", pagedown[0][:tokens][0].value
  end

  test "parses key with count and leading space" do
    result = parse("  Tab 3\n")

    command = result[0]
    assert_equal 4, command[:tokens].size

    assert_instance_of DemoTape::Token::LeadingSpace, command[:tokens][0]
    assert_equal "Tab", command[:tokens][1].value
    assert_instance_of DemoTape::Token::Space, command[:tokens][2]
    assert_equal 3, command[:tokens][3].value
  end

  test "parses keys inside Group" do
    source = <<~TAPE
      Group setup do
        Ctrl+L
        Type "clear"
        Enter
      end
    TAPE

    result = parse(source)
    group = result[0]

    assert_equal :group, group[:type]

    commands = group[:children].select do |item|
      item.is_a?(Hash) && item[:type] == :command
    end
    assert_equal 3, commands.size

    # First command: Ctrl+L
    assert_equal "Ctrl", commands[0][:tokens][1].value
    assert_equal "+", commands[0][:tokens][2].value
    assert_equal "L", commands[0][:tokens][3].value

    # Second command: Type "clear"
    assert_equal "Type", commands[1][:tokens][1].value

    # Third command: Enter
    assert_equal "Enter", commands[2][:tokens][1].value
  end

  test "parses key with duration and count" do
    result = parse("Down@.5 3\n")

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 5, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Down", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Operator, command[:tokens][1]

    assert_instance_of DemoTape::Token::Number, command[:tokens][2]
    assert_in_delta(0.5, command[:tokens][2].value)

    assert_instance_of DemoTape::Token::Space, command[:tokens][3]

    assert_instance_of DemoTape::Token::Number, command[:tokens][4]
    assert_equal 3, command[:tokens][4].value
  end

  test "parses Enter with duration and count" do
    result = parse("Enter@.5 2\n")

    command = result[0]
    assert_equal :command, command[:type]

    assert_equal "Enter", command[:tokens][0].value
    assert_in_delta(0.5, command[:tokens][2].value)
    assert_equal 2, command[:tokens][4].value
  end

  test "parses Up with duration and count" do
    result = parse("Up@.5 2\n")

    command = result[0]
    assert_equal :command, command[:type]

    assert_equal "Up", command[:tokens][0].value
    assert_in_delta(0.5, command[:tokens][2].value)
    assert_equal 2, command[:tokens][4].value
  end
end
