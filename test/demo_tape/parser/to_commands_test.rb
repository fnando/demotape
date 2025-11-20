# frozen_string_literal: true

require "test_helper"

class ParserToCommandsTest < Minitest::Test
  def parse_and_convert(source)
    parser = DemoTape::Parser.new
    parsed = parser.parse(source)
    parser.to_commands(parsed)
  end

  test "converts Type command" do
    commands = parse_and_convert(%[Type "hello world"\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "Type", cmd.type
    assert_equal "hello world", cmd.args
    assert_empty(cmd.options)
  end

  test "converts Set command with comma-separated values" do
    commands = parse_and_convert(%[Set margin 10, 20, 30, 40\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "Set", cmd.type
    assert_equal [10, 20, 30, 40], cmd.args
    assert_equal({option: "margin"}, cmd.options)
  end

  test "converts Set command with single value" do
    commands = parse_and_convert(%[Set theme.bg "#ffffff"\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "Set", cmd.type
    assert_equal "#ffffff", cmd.args
    assert_equal({option: "theme.bg"}, cmd.options)
  end

  test "converts key command with count" do
    commands = parse_and_convert(%[Down 5\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "Down", cmd.type
    assert_equal "", cmd.args
    assert_equal({count: 5}, cmd.options)
  end

  test "converts key command with duration" do
    commands = parse_and_convert(%[Down@1s\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "Down", cmd.type
    assert_equal "", cmd.args
    assert_equal({duration: 1.0}, cmd.options)
  end

  test "converts key command with duration and count" do
    commands = parse_and_convert(%[Down@1s 3\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "Down", cmd.type
    assert_equal "", cmd.args
    assert_equal({duration: 1.0, count: 3}, cmd.options)
  end

  test "converts key command with duration without unit" do
    commands = parse_and_convert(%[Down@0.5\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "Down", cmd.type
    assert_equal({duration: 0.5}, cmd.options)
  end

  test "converts key command with additional keys" do
    commands = parse_and_convert(%[Cmd+C\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "Cmd", cmd.type
    assert_equal({keys: ["C"]}, cmd.options)
  end

  test "converts key command with multiple additional keys" do
    commands = parse_and_convert(%[Cmd+Shift+P\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "Cmd", cmd.type
    assert_equal({keys: %w[Shift P]}, cmd.options)
  end

  test "converts Group with children" do
    source = <<~TAPE
      Group setup do
        Type "echo setup"
        Enter
      end
    TAPE

    commands = parse_and_convert(source)

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "Group", cmd.type
    assert_equal "setup", cmd.args
    assert cmd.group?
    assert_equal 2, cmd.children.size

    assert_equal "Type", cmd.children[0].type
    assert_equal "echo setup", cmd.children[0].args

    assert_equal "Enter", cmd.children[1].type
  end

  test "converts group invocation" do
    source = <<~TAPE
      Group setup do
        Type "test"
      end

      setup
    TAPE

    commands = parse_and_convert(source)

    assert_equal 2, commands.size

    # First is the group definition
    assert_equal "Group", commands[0].type

    # Second is the group invocation
    assert_equal "setup", commands[1].type
    assert_equal "", commands[1].args
  end

  test "preserves line and column information" do
    source = <<~TAPE
      Type "line1"
      Down 3
    TAPE

    commands = parse_and_convert(source)

    assert_equal 1, commands[0].line
    assert_equal 2, commands[1].line
  end

  test "converts Run command" do
    commands = parse_and_convert(%[Run "ls -la"\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "Run", cmd.type
    assert_equal "ls -la", cmd.args
  end

  test "converts Sleep command" do
    commands = parse_and_convert(%[Sleep 2s\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "Sleep", cmd.type
    assert_equal "", cmd.args
    assert_equal({duration: 2.0}, cmd.options)
  end

  test "converts Sleep command with number only" do
    commands = parse_and_convert(%[Sleep 10\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "Sleep", cmd.type
    assert_equal "", cmd.args
    assert_equal({duration: 10.0}, cmd.options)
  end

  test "skips comments and keeps only commands" do
    source = <<~TAPE
      # This is a comment
      Type "hello"
      # Another comment
      Enter
    TAPE

    commands = parse_and_convert(source)

    assert_equal 2, commands.size
    assert_equal "Type", commands[0].type
    assert_equal "Enter", commands[1].type
  end

  test "handles empty source" do
    commands = parse_and_convert("")

    assert_equal 0, commands.size
  end

  test "handles source with only comments" do
    source = <<~TAPE
      # Comment 1
      # Comment 2
    TAPE

    commands = parse_and_convert(source)

    assert_equal 0, commands.size
  end

  test "converts WaitUntil with regex" do
    commands = parse_and_convert(%[WaitUntil /true/\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "WaitUntil", cmd.type
    assert_equal "true", cmd.args
    assert_empty(cmd.options)
  end

  test "converts WaitUntil with duration and regex" do
    commands = parse_and_convert(%[WaitUntil@30s /Done!/\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "WaitUntil", cmd.type
    assert_equal "Done!", cmd.args
    assert_equal({duration: 30.0}, cmd.options)
  end

  test "converts Wait command with number only" do
    commands = parse_and_convert(%[Wait 5\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "Wait", cmd.type
    assert_equal "", cmd.args
    assert_equal({duration: 5.0}, cmd.options)
  end

  test "converts key command with float duration and count" do
    commands = parse_and_convert(%[Down@.5 2\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "Down", cmd.type
    assert_equal "", cmd.args
    assert_equal({duration: 0.5, count: 2}, cmd.options)
  end

  test "converts Set command with theme property" do
    commands = parse_and_convert(%[Set theme.foreground "#ff0000"\n])

    assert_equal 1, commands.size
    cmd = commands[0]

    assert_equal "Set", cmd.type
    assert_equal "#ff0000", cmd.args
    assert_equal({option: "theme.foreground"}, cmd.options)
  end
end
