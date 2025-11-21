# frozen_string_literal: true

require "simplecov"
SimpleCov.start

require "bundler/setup"
require "demo_tape"

require "minitest/utils"
require "minitest/autorun"

Dir["#{__dir__}/support/**/*.rb"].each do |file|
  require file
end

module Minitest
  class Test
    def parse(tape)
      DemoTape::Parser.new.parse(tape)
    end

    def to_commands(tape)
      parser = DemoTape::Parser.new
      parser.to_commands(parser.parse(tape))
    end
  end
end
