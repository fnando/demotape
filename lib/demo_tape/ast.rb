# frozen_string_literal: true

module DemoTape
  module AST
    # Base class for all AST nodes
    class Node
      attr_reader :line, :column, :file

      def initialize(line:, column:, file: nil)
        @line = line
        @column = column
        @file = file
      end
    end

    # Represents a command with its tokens
    class CommandNode < Node
      attr_reader :tokens

      def initialize(tokens:, line:, column:, file: nil)
        super(line: line, column: column, file: file)
        @tokens = tokens
      end

      def type
        # First identifier token is the command type
        first_identifier = tokens.find {|t| t.is_a?(Token::Identifier) }
        first_identifier&.value
      end

      def to_source
        tokens.map(&:value).join
      end
    end

    # Represents a block (Group) with nested nodes
    class BlockNode < Node
      attr_reader :name, :body, :tokens

      def initialize(name:, body:, tokens:, line:, column:, file: nil)
        super(line: line, column: column, file: file)
        @name = name
        @body = body
        @tokens = tokens
      end

      def to_source
        result = "#{tokens[0].value} #{name} do\n"
        body.each do |node|
          result += "  #{node.to_source}\n"
        end
        result += "end"
        result
      end
    end

    # Represents a comment line
    class CommentNode < Node
      attr_reader :token

      def initialize(token:, line:, column:, file: nil)
        super(line: line, column: column, file: file)
        @token = token
      end

      def text
        token.value
      end

      def to_source
        token.value
      end
    end

    # Represents a blank line
    class BlankLineNode < Node
      def to_source
        ""
      end
    end

    # Root node containing all top-level nodes
    class DocumentNode
      attr_reader :nodes

      def initialize(nodes)
        @nodes = nodes
      end

      def to_source
        nodes.map(&:to_source).join("\n")
      end

      # Convert AST to Command objects (backward compatibility)
      def to_commands
        command_nodes = nodes.select do |n|
          n.is_a?(CommandNode) || n.is_a?(BlockNode)
        end
        command_nodes.map {|node| node_to_command(node) }
      end

      private def node_to_command(node)
        case node
        when CommandNode
          command_from_command_node(node)
        when BlockNode
          command_from_block_node(node)
        end
      end

      private def command_from_command_node(node)
        # Extract command info from tokens
        identifiers = node.tokens.select {|t| t.is_a?(Token::Identifier) }
        type = identifiers[0]&.value

        # For now, just create a basic command
        # The full logic needs to parse args, options, etc.
        cmd = Command.new(type, "")
        cmd.tokens = node.tokens
        cmd.line = node.line
        cmd.column = node.column
        cmd.file = node.file
        cmd
      end

      private def command_from_block_node(node)
        cmd = Command.new("Group", node.name)
        cmd.tokens = node.tokens
        cmd.line = node.line
        cmd.column = node.column
        cmd.file = node.file

        # Recursively convert child nodes
        cmd.children.replace(node.body.map do |child_node|
          node_to_command(child_node)
        end)
        cmd
      end
    end
  end
end
