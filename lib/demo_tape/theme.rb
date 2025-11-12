# frozen_string_literal: true

module DemoTape
  Theme = Struct.new(
    "Theme",
    :background,
    :foreground,
    :cursor,
    :cursor_accent,
    :black,
    :red,
    :green,
    :yellow,
    :blue,
    :magenta,
    :cyan,
    :white,
    :bright_black,
    :bright_red,
    :bright_green,
    :bright_yellow,
    :bright_blue,
    :bright_magenta,
    :bright_cyan,
    :bright_white,
    :selection_background,
    :selection_foreground,
    :selection_inactive_background,
    keyword_init: true
  ) do
    def self.load(path)
    end

    def self.valid_options
      @valid_options ||= new.to_h.keys
    end

    def to_json(*)
      as_json.to_json
    end

    def as_json(*)
      to_h.transform_keys do |key|
        words = key.to_s.split("_")
        words[0] + words[1..].map(&:capitalize).join
      end
    end
  end
end
