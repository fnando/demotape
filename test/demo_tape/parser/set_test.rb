# frozen_string_literal: true

require "test_helper"

class ParserSetTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses Set with single number value" do
    result = parse("Set width 1280\n")

    assert_equal 2, result.size

    command = result[0]
    assert_equal :command, command[:type]
    assert_equal 5, command[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][0]
    assert_equal "Set", command[:tokens][0].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][1]

    assert_instance_of DemoTape::Token::Identifier, command[:tokens][2]
    assert_equal "width", command[:tokens][2].value

    assert_instance_of DemoTape::Token::Space, command[:tokens][3]

    assert_instance_of DemoTape::Token::Number, command[:tokens][4]
    assert_equal 1280, command[:tokens][4].value
  end

  test "parses Set with string value" do
    result = parse("Set theme \"default\"\n")

    command = result[0]
    assert_equal 5, command[:tokens].size

    assert_equal "Set", command[:tokens][0].value
    assert_equal "theme", command[:tokens][2].value
    assert_instance_of DemoTape::Token::String, command[:tokens][4]
    assert_equal "default", command[:tokens][4].value
  end

  test "parses Set with dotted property" do
    result = parse("Set theme.background \"#222222\"\n")

    command = result[0]
    assert_equal 5, command[:tokens].size

    assert_equal "Set", command[:tokens][0].value
    assert_equal "theme.background", command[:tokens][2].value
    assert_equal "#222222", command[:tokens][4].value
  end

  test "parses Set with boolean true" do
    result = parse("Set cursor_blink true\n")

    command = result[0]
    assert_equal 5, command[:tokens].size

    assert_equal "cursor_blink", command[:tokens][2].value
    assert_instance_of DemoTape::Token::Identifier, command[:tokens][4]
    assert_equal "true", command[:tokens][4].value
  end

  test "parses Set with boolean false" do
    result = parse("Set cursor_blink false\n")

    command = result[0]
    assert_equal 5, command[:tokens].size

    assert_equal "cursor_blink", command[:tokens][2].value
    assert_equal "false", command[:tokens][4].value
  end

  test "parses Set with time value" do
    result = parse("Set run_enter_delay 300ms\n")

    command = result[0]
    assert_equal 5, command[:tokens].size

    assert_equal "run_enter_delay", command[:tokens][2].value
    assert_instance_of DemoTape::Token::Duration, command[:tokens][4]
    assert_equal({number: 300, unit: "ms", raw: "300ms"},
                 command[:tokens][4].value)
  end

  test "parses Set padding with 1 value" do
    result = parse("Set padding 20\n")

    command = result[0]
    assert_equal 5, command[:tokens].size
    assert_equal "padding", command[:tokens][2].value
    assert_equal 20, command[:tokens][4].value
  end

  test "parses Set padding with 2 values" do
    result = parse("Set padding 10, 20\n")

    command = result[0]
    assert_equal 8, command[:tokens].size

    assert_equal "padding", command[:tokens][2].value
    assert_equal 10, command[:tokens][4].value
    assert_instance_of DemoTape::Token::Operator, command[:tokens][5]
    assert_equal ",", command[:tokens][5].value
    assert_equal 20, command[:tokens][7].value
  end

  test "parses Set padding with 3 values" do
    result = parse("Set padding 10, 20, 30\n")

    command = result[0]
    assert_equal 11, command[:tokens].size

    assert_equal "padding", command[:tokens][2].value
    assert_equal 10, command[:tokens][4].value
    assert_equal ",", command[:tokens][5].value
    assert_equal 20, command[:tokens][7].value
    assert_equal ",", command[:tokens][8].value
    assert_equal 30, command[:tokens][10].value
  end

  test "parses Set padding with 4 values" do
    result = parse("Set padding 10, 20, 30, 40\n")

    command = result[0]
    assert_equal 14, command[:tokens].size

    assert_equal "padding", command[:tokens][2].value
    assert_equal 10, command[:tokens][4].value
    assert_equal ",", command[:tokens][5].value
    assert_equal 20, command[:tokens][7].value
    assert_equal ",", command[:tokens][8].value
    assert_equal 30, command[:tokens][10].value
    assert_equal ",", command[:tokens][11].value
    assert_equal 40, command[:tokens][13].value
  end

  test "parses Set margin with 1 value" do
    result = parse("Set margin 60\n")

    command = result[0]
    assert_equal 5, command[:tokens].size
    assert_equal "margin", command[:tokens][2].value
    assert_equal 60, command[:tokens][4].value
  end

  test "parses Set margin with 2 values" do
    result = parse("Set margin 20, 40\n")

    command = result[0]
    assert_equal 8, command[:tokens].size

    assert_equal "margin", command[:tokens][2].value
    assert_equal 20, command[:tokens][4].value
    assert_equal ",", command[:tokens][5].value
    assert_equal 40, command[:tokens][7].value
  end

  test "parses Set margin with 3 values" do
    result = parse("Set margin 10, 20, 30\n")

    command = result[0]
    assert_equal 11, command[:tokens].size

    assert_equal "margin", command[:tokens][2].value
    assert_equal 10, command[:tokens][4].value
    assert_equal ",", command[:tokens][5].value
    assert_equal 20, command[:tokens][7].value
    assert_equal ",", command[:tokens][8].value
    assert_equal 30, command[:tokens][10].value
  end

  test "parses Set margin with 4 values" do
    result = parse("Set margin 10, 20, 30, 40\n")

    command = result[0]
    assert_equal 14, command[:tokens].size

    assert_equal "margin", command[:tokens][2].value
    assert_equal 10, command[:tokens][4].value
    assert_equal ",", command[:tokens][5].value
    assert_equal 20, command[:tokens][7].value
    assert_equal ",", command[:tokens][8].value
    assert_equal 30, command[:tokens][10].value
    assert_equal ",", command[:tokens][11].value
    assert_equal 40, command[:tokens][13].value
  end

  test "parses Set padding without spaces after commas" do
    result = parse("Set padding 10,20,30,40\n")

    command = result[0]
    assert_equal 11, command[:tokens].size

    assert_equal "padding", command[:tokens][2].value
    assert_equal 10, command[:tokens][4].value
    assert_equal ",", command[:tokens][5].value
    assert_equal 20, command[:tokens][6].value
    assert_equal ",", command[:tokens][7].value
    assert_equal 30, command[:tokens][8].value
    assert_equal ",", command[:tokens][9].value
    assert_equal 40, command[:tokens][10].value
  end

  test "parses Set padding with mixed spacing" do
    result = parse("Set padding 10,20, 30 ,40\n")

    command = result[0]
    assert_equal 13, command[:tokens].size

    assert_equal "padding", command[:tokens][2].value
    assert_equal 10, command[:tokens][4].value
    assert_equal ",", command[:tokens][5].value
    assert_equal 20, command[:tokens][6].value
    assert_equal ",", command[:tokens][7].value
    assert_equal 30, command[:tokens][9].value
    assert_equal ",", command[:tokens][11].value
    assert_equal 40, command[:tokens][12].value
  end

  test "parses Set with font_family string" do
    result = parse("Set font_family \"Menlo\"\n")

    command = result[0]
    assert_equal "font_family", command[:tokens][2].value
    assert_equal "Menlo", command[:tokens][4].value
  end

  test "parses Set with font_size" do
    result = parse("Set font_size 16\n")

    command = result[0]
    assert_equal "font_size", command[:tokens][2].value
    assert_equal 16, command[:tokens][4].value
  end

  test "parses Set with line_height decimal" do
    result = parse("Set line_height 1.5\n")

    command = result[0]
    assert_equal "line_height", command[:tokens][2].value
    assert_in_delta(1.5, command[:tokens][4].value)
  end

  test "parses Set with cursor_style" do
    styles = %w[block bar underline]

    styles.each do |style|
      result = parse("Set cursor_style \"#{style}\"\n")
      command = result[0]

      assert_equal "cursor_style", command[:tokens][2].value
      assert_equal style, command[:tokens][4].value
    end
  end

  test "parses Set with margin_fill color" do
    result = parse("Set margin_fill \"#6b50ff\"\n")

    command = result[0]
    assert_equal "margin_fill", command[:tokens][2].value
    assert_equal "#6b50ff", command[:tokens][4].value
  end

  test "parses Set with margin_fill image path" do
    result = parse("Set margin_fill \"examples/background.png\"\n")

    command = result[0]
    assert_equal "margin_fill", command[:tokens][2].value
    assert_equal "examples/background.png", command[:tokens][4].value
  end

  test "parses Set with run_sleep duration" do
    result = parse("Set run_sleep 1s\n")

    command = result[0]
    assert_equal "run_sleep", command[:tokens][2].value
    assert_equal({number: 1, unit: "s", raw: "1s"}, command[:tokens][4].value)
  end

  test "parses Set with height" do
    result = parse("Set height 720\n")

    command = result[0]
    assert_equal "height", command[:tokens][2].value
    assert_equal 720, command[:tokens][4].value
  end

  test "parses Set with theme path" do
    result = parse("Set theme \"themes/some_theme.json\"\n")

    command = result[0]
    assert_equal "theme", command[:tokens][2].value
    assert_equal "themes/some_theme.json", command[:tokens][4].value
  end

  test "parses Set with theme.foreground" do
    result = parse("Set theme.foreground \"#ffffff\"\n")

    command = result[0]
    assert_equal "theme.foreground", command[:tokens][2].value
    assert_equal "#ffffff", command[:tokens][4].value
  end

  test "parses Set with theme.cursor" do
    result = parse("Set theme.cursor \"#00ff00\"\n")

    command = result[0]
    assert_equal "theme.cursor", command[:tokens][2].value
    assert_equal "#00ff00", command[:tokens][4].value
  end

  test "parses Set with theme.selection" do
    result = parse("Set theme.selection \"#444444\"\n")

    command = result[0]
    assert_equal "theme.selection", command[:tokens][2].value
    assert_equal "#444444", command[:tokens][4].value
  end

  test "parses Set with leading space" do
    result = parse("  Set width 800\n")

    command = result[0]
    assert_equal 6, command[:tokens].size

    assert_instance_of DemoTape::Token::LeadingSpace, command[:tokens][0]
    assert_equal "  ", command[:tokens][0].value

    assert_equal "Set", command[:tokens][1].value
    assert_equal "width", command[:tokens][3].value
    assert_equal 800, command[:tokens][5].value
  end

  test "parses multiple Set commands" do
    source = <<~TAPE
      Set width 1280
      Set height 720
      Set theme "default"
    TAPE

    result = parse(source)

    commands = result.select do |item|
      item.is_a?(Hash) && item[:type] == :command
    end
    assert_equal 3, commands.size

    assert_equal "width", commands[0][:tokens][2].value
    assert_equal "height", commands[1][:tokens][2].value
    assert_equal "theme", commands[2][:tokens][2].value
  end

  test "preserves line and column info" do
    result = parse("Set width 1280\n")

    command = result[0]
    assert_equal 1, command[:line]
    assert_equal 1, command[:column]

    set_token = command[:tokens][0]
    assert_equal 1, set_token.line
    assert_equal 1, set_token.column

    property = command[:tokens][2]
    assert_equal 1, property.line
    assert_equal 5, property.column

    value = command[:tokens][4]
    assert_equal 1, value.line
    assert_equal 11, value.column
  end

  test "preserves line and column info with dotted property" do
    result = parse("Set theme.background \"#000\"\n")

    command = result[0]

    property = command[:tokens][2]
    assert_equal 1, property.line
    assert_equal 5, property.column

    value = command[:tokens][4]
    assert_equal 1, value.line
    assert_equal 22, value.column
  end

  test "parses Set inside Group" do
    source = <<~TAPE
      Group config do
        Set width 1280
        Set height 720
        Type "hello"
      end
    TAPE

    result = parse(source)
    group = result[0]

    assert_equal :group, group[:type]

    commands = group[:children].select do |item|
      item.is_a?(Hash) && item[:type] == :command
    end
    assert_equal 3, commands.size

    # First two are Set commands
    assert_equal "Set", commands[0][:tokens][1].value
    assert_equal "width", commands[0][:tokens][3].value

    assert_equal "Set", commands[1][:tokens][1].value
    assert_equal "height", commands[1][:tokens][3].value
  end

  test "parses Set with extra spaces around comma" do
    result = parse("Set padding 10  ,  20  ,  30\n")

    command = result[0]

    # Should have multiple space tokens
    assert_equal 10, command[:tokens][4].value
    assert_instance_of DemoTape::Token::Space, command[:tokens][5]
    assert_equal ",", command[:tokens][6].value
    assert_instance_of DemoTape::Token::Space, command[:tokens][7]
    assert_equal 20, command[:tokens][8].value
  end

  test "parses Set with trailing space" do
    result = parse("Set width 800  \n")

    command = result[0]
    assert_instance_of DemoTape::Token::TrailingSpace, command[:tokens].last
    assert_equal "  ", command[:tokens].last.value
  end

  test "parses Set with underscore in property name" do
    result = parse("Set font_family \"Courier\"\n")

    command = result[0]
    assert_equal "font_family", command[:tokens][2].value
  end

  test "parses Set with float value" do
    result = parse("Set line_height 0.75\n")

    command = result[0]
    assert_equal "line_height", command[:tokens][2].value
    assert_in_delta(0.75, command[:tokens][4].value)
  end

  test "parses Set with zero value" do
    result = parse("Set padding 0\n")

    command = result[0]
    assert_equal "padding", command[:tokens][2].value
    assert_equal 0, command[:tokens][4].value
  end

  test "parses Set with negative value" do
    result = parse("Set margin -10\n")

    command = result[0]
    assert_equal 5, command[:tokens].size
    assert_equal "margin", command[:tokens][2].value
    assert_equal(-10, command[:tokens][4].value)
  end

  test "parses Set with time in seconds" do
    result = parse("Set loop_delay 5s\n")

    command = result[0]
    assert_equal "loop_delay", command[:tokens][2].value
    assert_equal({number: 5, unit: "s", raw: "5s"}, command[:tokens][4].value)
  end

  test "parses Set with time in minutes" do
    result = parse("Set loop_delay 2m\n")

    command = result[0]
    assert_equal "loop_delay", command[:tokens][2].value
    assert_equal({number: 2, unit: "m", raw: "2m"}, command[:tokens][4].value)
  end

  test "parses Set cursor_width" do
    result = parse("Set cursor_width 5\n")

    command = result[0]
    assert_equal "cursor_width", command[:tokens][2].value
    assert_equal 5, command[:tokens][4].value
  end

  test "parses Set border_radius" do
    result = parse("Set border_radius 30\n")

    command = result[0]
    assert_equal "border_radius", command[:tokens][2].value
    assert_equal 30, command[:tokens][4].value
  end

  test "parses Set loop with boolean" do
    result = parse("Set loop false\n")

    command = result[0]
    assert_equal "loop", command[:tokens][2].value
    assert_equal "false", command[:tokens][4].value
  end

  test "parses Set loop_delay with duration" do
    result = parse("Set loop_delay 2s\n")

    command = result[0]
    assert_equal "loop_delay", command[:tokens][2].value
    assert_equal({number: 2, unit: "s", raw: "2s"}, command[:tokens][4].value)
  end

  test "fails when Set loop_delay has invalid duration unit" do
    error = assert_raises(DemoTape::ParseError) do
      parse("Set loop_delay 2ns\n")
    end

    expected = "Invalid unit \"ns\" in duration at <unknown>:1:16:\n" \
               "  Set loop_delay 2ns\n" \
               "                 ^"

    assert_equal expected, error.message
  end
end
