# frozen_string_literal: true

module DemoTape
  require "json"
  require "strscan"
  require "base64"
  require "shellwords"
  require "pathname"
  require "capybara"
  require "chunky_png"
  require "socket"
  require "timeout"
  require "tty-spinner"

  require_relative "demo_tape/version"
  require_relative "demo_tape/command"
  require_relative "demo_tape/spacing"
  require_relative "demo_tape/bounds"
  require_relative "demo_tape/token"
  require_relative "demo_tape/parser/helpers"
  require_relative "demo_tape/parser/rules"
  require_relative "demo_tape/parser"
  require_relative "demo_tape/lexer"
  require_relative "demo_tape/runner"
  require_relative "demo_tape/exporter"
  require_relative "demo_tape/duration"
  require_relative "demo_tape/theme"
  require_relative "demo_tape/ttyd"
  require_relative "demo_tape/spinner"
  require_relative "demo_tape/formatter"

  ParseError = Class.new(StandardError)
end
