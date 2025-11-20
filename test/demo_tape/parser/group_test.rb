# frozen_string_literal: true

require "test_helper"

class ParserGroupTest < Minitest::Test
  def parse(source)
    DemoTape::Parser.new.parse(source)
  end

  test "parses basic Group block" do
    source = <<~TAPE
      Group hello do
        Type "Hello, World!"
      end
    TAPE

    result = parse(source)

    assert_equal 1, result.size

    group = result[0]
    assert_equal :group, group[:type]
    assert_equal 5, group[:tokens].size

    assert_instance_of DemoTape::Token::Identifier, group[:tokens][0]
    assert_equal "Group", group[:tokens][0].value
    assert_equal 1, group[:tokens][0].line
    assert_equal 1, group[:tokens][0].column

    assert_instance_of DemoTape::Token::Space, group[:tokens][1]

    assert_instance_of DemoTape::Token::Identifier, group[:tokens][2]
    assert_equal "hello", group[:tokens][2].value

    assert_instance_of DemoTape::Token::Space, group[:tokens][3]

    assert_instance_of DemoTape::Token::Keyword, group[:tokens][4]
    assert_equal "do", group[:tokens][4].value

    # Group should have children
    assert_instance_of Array, group[:children]
    assert_equal 3, group[:children].size

    newline1 = group[:children][0]
    assert_instance_of DemoTape::Token::Newline, newline1

    command = group[:children][1]
    assert_equal :command, command[:type]
    assert_equal 4, command[:tokens].size
    assert_equal "Type", command[:tokens][1].value
    assert_equal "Hello, World!", command[:tokens][3].value

    newline2 = group[:children][2]
    assert_instance_of DemoTape::Token::Newline, newline2
  end

  test "parses Group with multiple commands" do
    source = <<~TAPE
      Group setup do
        Type "echo 'Hello'"
        Type "echo 'Goodbye'"
        Run "ls -la"
      end
    TAPE

    result = parse(source)
    group = result[0]

    assert_equal :group, group[:type]

    commands = group[:children].select do |item|
      item.is_a?(Hash) && item[:type] == :command
    end
    assert_equal 3, commands.size

    assert_equal "Type", commands[0][:tokens][1].value
    assert_equal "echo 'Hello'", commands[0][:tokens][3].value

    assert_equal "Type", commands[1][:tokens][1].value
    assert_equal "echo 'Goodbye'", commands[1][:tokens][3].value

    assert_equal "Run", commands[2][:tokens][1].value
    assert_equal "ls -la", commands[2][:tokens][3].value
  end

  test "parses Group with leading space" do
    source = "  Group indented do\n    Type \"test\"\n  end\n"

    result = parse(source)
    group = result[0]

    assert_equal :group, group[:type]
    # Leading space is part of group tokens
    assert_instance_of DemoTape::Token::LeadingSpace, group[:tokens][0]
    assert_equal "  ", group[:tokens][0].value
    assert_equal "Group", group[:tokens][1].value
  end

  test "parses Group with comment inside" do
    source = <<~TAPE
      Group with_comment do
        # This is a setup step
        Type "setup"
      end
    TAPE

    result = parse(source)
    group = result[0]

    assert_equal :group, group[:type]

    comment = group[:children]
              .find {|item| item.is_a?(DemoTape::Token::Comment) }

    refute_nil comment
    assert_equal "# This is a setup step", comment.value
  end

  test "parses Group with empty body" do
    source = <<~TAPE
      Group empty do
      end
    TAPE

    result = parse(source)
    group = result[0]

    assert_equal :group, group[:type]
    assert_equal "empty", group[:tokens][2].value

    # Empty body still has the newline after "do"
    assert_equal 1, group[:children].size
    assert_instance_of DemoTape::Token::Newline, group[:children][0]
  end

  test "parses multiple Groups" do
    source = <<~TAPE
      Group first do
        Type "one"
      end

      Group second do
        Type "two"
      end
    TAPE

    result = parse(source)

    groups = result.select {|item| item.is_a?(Hash) && item[:type] == :group }
    assert_equal 2, groups.size

    assert_equal "first", groups[0][:tokens][2].value
    assert_equal "second", groups[1][:tokens][2].value
  end

  test "parses Group name with various characters" do
    [
      %w[setup setup],
      %w[my_group my_group],
      %w[group123 group123],
      %w[setUp setUp]
    ].each do |name, expected|
      source = "Group #{name} do\nend\n"
      result = parse(source)
      group = result[0]
      assert_equal expected, group[:tokens][2].value, "Failed for name: #{name}"
    end
  end

  test "preserves line and column info for Group" do
    source = <<~TAPE
      Group test do
        Type "hello"
      end
    TAPE

    result = parse(source)
    group = result[0]

    # Line info is from the start of the line
    assert_equal 1, group[:line]
    assert_equal 1, group[:column]

    group_token = group[:tokens][0]
    assert_equal 1, group_token.line
    assert_equal 1, group_token.column

    name_token = group[:tokens][2]
    assert_equal 1, name_token.line
    assert_equal 7, name_token.column

    do_token = group[:tokens][4]
    assert_equal 1, do_token.line
    assert_equal 12, do_token.column
  end

  test "preserves line and column info for Group with indentation" do
    source = "  Group indented do\n    Type \"test\"\n  end\n"

    result = parse(source)
    group = result[0]

    # Line info is from start of line, even with leading space
    assert_equal 1, group[:line]
    assert_equal 1, group[:column]

    leading_space = group[:tokens][0]
    assert_equal 1, leading_space.line
    assert_equal 1, leading_space.column

    group_token = group[:tokens][1]
    assert_equal 1, group_token.line
    assert_equal 3, group_token.column
  end

  test "parses Group with indented children" do
    source = "Group nested do\n  Type \"first\"\n    " \
             "Type \"indented\"\n  Type \"back\"\nend\n"

    result = parse(source)
    group = result[0]

    commands = group[:children].select do |item|
      item.is_a?(Hash) && item[:type] == :command
    end
    assert_equal 3, commands.size

    # Second command has 2 extra spaces of indentation (4 total vs 2)
    assert_instance_of DemoTape::Token::LeadingSpace, commands[1][:tokens][0]
    assert_equal "    ", commands[1][:tokens][0].value
  end

  test "parses Group with trailing space" do
    source = "Group test do  \n  Type \"hello\"\nend\n"

    result = parse(source)
    group = result[0]

    # Group tokens should include trailing space before newline
    trailing = group[:tokens]
               .find {|t| t.is_a?(DemoTape::Token::TrailingSpace) }

    refute_nil trailing
    assert_equal "  ", trailing.value
  end

  test "parses Group with mixed content types" do
    source = <<~TAPE
      Group mixed do
        # Comment 1
        Type "hello"

        # Comment 2
        Run "ls"
      end
    TAPE

    result = parse(source)
    group = result[0]
    comments = group[:children]
               .select {|item| item.is_a?(DemoTape::Token::Comment) }

    assert_equal 2, comments.size

    commands = group[:children].select do |item|
      item.is_a?(Hash) && item[:type] == :command
    end
    assert_equal 2, commands.size

    newlines = group[:children]
               .select {|item| item.is_a?(DemoTape::Token::Newline) }
    assert_operator newlines.size, :>, 0
  end

  test "parses Group with end keyword on same indentation" do
    source = <<~TAPE
      Group aligned do
        Type "test"
      end
    TAPE

    result = parse(source)
    group = result[0]

    assert_equal :group, group[:type]
    assert_equal "aligned", group[:tokens][2].value
  end

  test "parses Group with various spacing around keywords" do
    source = <<~TAPE
      Group    spaced    do
        Type "test"
      end
    TAPE

    result = parse(source)
    group = result[0]

    spaces = group[:tokens].select {|t| t.is_a?(DemoTape::Token::Space) }
    assert_operator spaces.size, :>=, 2
  end

  test "parses Group name case sensitivity" do
    source = <<~TAPE
      Group MyGroup do
        Type "test"
      end
    TAPE

    result = parse(source)
    group = result[0]

    assert_equal "MyGroup", group[:tokens][2].value
  end

  test "parses consecutive Groups without blank lines" do
    source = <<~TAPE
      Group first do
        Type "1"
      end
      Group second do
        Type "2"
      end
    TAPE

    result = parse(source)

    groups = result.select {|item| item.is_a?(Hash) && item[:type] == :group }
    assert_equal 2, groups.size
  end

  test "parses Group with Set commands inside" do
    source = <<~TAPE
      Group config do
        Set width 800
        Set height 600
        Type "configured"
      end
    TAPE

    result = parse(source)
    group = result[0]

    commands = group[:children].select do |item|
      item.is_a?(Hash) && item[:type] == :command
    end
    assert_equal 3, commands.size

    assert_equal "Set", commands[0][:tokens][1].value
    assert_equal "Set", commands[1][:tokens][1].value
    assert_equal "Type", commands[2][:tokens][1].value
  end

  test "parses Group with Sleep commands inside" do
    source = <<~TAPE
      Group paused do
        Type "before"
        Sleep 1s
        Type "after"
      end
    TAPE

    result = parse(source)
    group = result[0]

    commands = group[:children].select do |item|
      item.is_a?(Hash) && item[:type] == :command
    end
    assert_equal 3, commands.size

    assert_equal "Sleep", commands[1][:tokens][1].value
  end

  test "error reporting includes correct line and column for Group" do
    source = <<~TAPE
      # Comment
      Group test do
        Type "hello"
      end
    TAPE

    result = parse(source)

    # After comment and newline, the group is at index 2
    group = result.find {|item| item.is_a?(Hash) && item[:type] == :group }

    assert_equal 2, group[:line]
    assert_equal 1, group[:column]
  end
end
