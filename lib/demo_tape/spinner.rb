# frozen_string_literal: true

module DemoTape
  class Spinner
    attr_reader :phrase

    def initialize(phrases:)
      @phrases = phrases
      @shell = Thor::Shell::Color.new
      @phrase = @phrases.sample

      @spinner = TTY::Spinner.new(
        "           :spinner  :title",
        frames: [
          @shell.set_color("◉", :white),
          @shell.set_color("◎", :white),
          @shell.set_color("∙", :white)
        ],
        interval: 3,
        clear: true,
        hide_cursor: true
      )

      update(@phrase)

      @spinner.auto_spin
    end

    def update(phrase)
      @spinner.update(title: @shell.set_color(phrase, :white))
    end

    def stop
      @spinner.stop
    end
  end
end
