# frozen_string_literal: true

module DemoTape
  class Duration
    VALID_UNITS = %w[ms s m h].freeze

    def self.parse(input)
      input = "0#{input}" if input.to_s.start_with?(".")

      return input if input.is_a?(Numeric)
      return 1 if input.to_s.strip.empty?

      value, unit = *input.match(/((?:\d+\.)?(?:\d+))([a-z]{1,2})?/).captures

      unit ||= "s"

      case unit
      when "ms"
        value.to_f / 1000.0
      when "s"
        value.to_f
      when "m"
        value.to_f * 60.0
      when "h"
        value.to_f * 3600.0
      else
        raise ArgumentError, "Unknown time unit: #{unit.inspect}"
      end
    end
  end
end
