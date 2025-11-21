# frozen_string_literal: true

module DemoTape
  class Formatter
    attr_accessor :buffered_newlines

    def initialize(input)
      @input = input
      @buffered_newlines = 0
    end

    def newline?(token)
      token.instance_of?(Token::Newline)
    end

    def call
      parser = Parser.new
      tree = parser.parse(@input)

      meta = extract_meta!(tree)

      output = [
        collect(meta).flatten.compact.join.strip,
        collect(tree).flatten.compact.join.strip
      ].reject(&:empty?).join("\n\n")

      "#{output}\n"
    end

    def extract_meta!(tree, meta = [])
      tree.each do |node|
        next unless node.is_a?(Hash)

        if node[:type] == :command
          first_token = node[:tokens].reject(&:any_space?).first
          next unless first_token.meta?

          meta << node
          meta << Token::Newline.new("\n")
          tree.delete(node)
        elsif node[:type] == :group
          extract_meta!(node[:children], meta)
        end
      end

      meta
    end

    def collect(tree, output = [])
      query = Query.new(tree)

      tree.each_with_index do |node, _index|
        # Whenever we hit a non-newline, flush buffered newlines (first)
        # and then process the node. Newlines are clamped to max 2.
        unless newline?(node)
          newlines = buffered_newlines.clamp(0, 2)
          output << ("\n" * newlines)
          self.buffered_newlines = 0
        end

        case node
        when Token::Keyword
          output << node.value unless node.keyword?("end")
        when Token::Identifier
          output << if node.group?
                      "\n#{node.value}"
                    else
                      node.value
                    end
        when Token::Duration, Token::Comment
          output << node.value
        when Token::Newline
          self.buffered_newlines += 1
        when Token::Number
          value = [node.value.to_s]
          value << "s" if query.previous_identifier?(node, /Sleep|Wait/)
          output << value.join
        when Token::String
          output << normalize_string(node)
        when Token::MultilineString
          output << %["""\n#{node.value.chomp}\n"""\n]
        when Token::Space
          output << " "
        when Token::LeadingSpace
          next if output.empty?
          next unless within_group?

          output << "  "
        when Hash
          output = [output.flatten.compact.join]
          output << collect(node[:tokens])

          if node[:type] == :group
            within_group do
              output << "\n  "
              output << collect(node[:children]).join.strip
              output << "\nend"
              self.buffered_newlines += 1
            end
          end
        else
          output << node.raw
        end
      end

      output
    end

    def within_group?
      @within_group
    end

    def within_group
      @within_group = true
      yield
    ensure
      @within_group = false
    end

    def normalize_string(token)
      %["#{token.value}"]
    end

    class Query
      attr_reader :nodes

      def initialize(nodes)
        @nodes = nodes
      end

      def previous_identifier?(current_node, value)
        index = nodes.index(current_node)
        return false if index.nil? || index.zero?

        previous_node = nodes[index - 2]

        previous_node.is_a?(Token::Identifier) &&
          previous_node.value.match?(value)
      end
    end
  end
end
