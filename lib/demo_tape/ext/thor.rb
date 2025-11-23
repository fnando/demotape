# frozen_string_literal: true

require "thor/parser/argument"

class Thor
  class Argument
    def print_default
      if (@type == :array) && @default.is_a?(Array)
        @default.map do |item|
          item.respond_to?(:dump) ? item.dump : item
        end.join(" ")
      else
        @default
      end
    end
  end
end
