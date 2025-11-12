# frozen_string_literal: true

require "thor"

module DemoTape
  class CLI < Thor
    check_unknown_options!

    def self.exit_on_failure?
      true
    end

    desc "run PATH", "Runs a demo tape"
    option :typing_speed,
           type: :string,
           default: "50ms",
           desc: "Global speed for typing"
    option :variable_typing,
           type: :numeric,
           default: 0.25,
           desc: "Whether to add variability to typing speed"
    option :port,
           type: :numeric,
           default: 0,
           desc: "Port for the ttyd server"
    option :output_path,
           type: :array,
           default: [],
           desc: "One or more paths to save the recorded terminal session"
    option :shell,
           type: :string,
           enum: %w[zsh fish bash],
           default: "zsh",
           desc: "Shell to use for the terminal session"
    option :rc_file,
           type: :string,
           desc: "Path to a shell rc file to source on startup"
    option :no_rc,
           type: :boolean,
           default: false,
           desc: "Do not load the default rc file"
    option :theme,
           type: :string,
           default: "default_dark",
           desc: "A built-in theme name or a path to a custom theme JSON file"
    option :width,
           type: :numeric,
           default: 1920,
           desc: "Output video width"
    option :height,
           type: :numeric,
           default: 1080,
           desc: "Output video height"
    option :font_size,
           type: :numeric,
           default: 32,
           desc: "Font size for the terminal session"
    option :font_family,
           type: :string,
           default: %['JetBrainsMono Nerd Font Propo', monospace],
           desc: "Font family for the terminal session"
    option :line_height,
           type: :numeric,
           default: 1.2,
           desc: "Line height for the terminal session"
    option :cursor_blink,
           type: :boolean,
           default: true,
           desc: "Whether the cursor blinks"
    option :cursor_width,
           type: :numeric,
           default: 2,
           desc: "The width of the cursor when in 'bar' style"
    option :cursor_style,
           type: :string,
           enum: %w[block underline bar],
           default: "block",
           desc: "The style of the cursor when the terminal is focused."
    option :letter_spacing,
           type: :numeric,
           default: 0,
           desc: "Letter spacing for the terminal session"
    option :padding,
           type: :array,
           default: [50],
           desc: "Padding around the terminal content. " \
                 "It can be 1, 2, or 4 numbers."
    option :fps,
           type: :numeric,
           default: 24,
           desc: "Frames per second for the output video"
    option :overwrite,
           type: :boolean,
           default: false,
           desc: "Whether to overwrite the output file if it exists"
    option :debug,
           type: :boolean,
           default: false,
           desc: "Show additional debug output"
    option :loop,
           type: :boolean,
           default: true,
           desc: "Loop the GIF infinitely"
    option :loop_delay,
           type: :numeric,
           default: 0,
           desc: "Delay time (in seconds) before restarting the GIF animation"
    option :margin,
           type: :array,
           default: [0],
           desc: "Margin around the terminal content. " \
                 "It can be 1, 2, or 4 numbers."
    option :margin_fill,
           type: :string,
           default: "#000000",
           desc: "Color or image to use for the margin around the terminal " \
                 "content"
    option :border_radius,
           type: :numeric,
           default: 0,
           desc: "Border radius for the terminal canvas"
    option :screenshot_only,
           type: :boolean,
           desc: "Only take screenshots instead of recording a video"
    option :screenshot,
           type: :boolean,
           default: false,
           desc: "Take a single screenshot at the end of the session"
    def _run(file_path = "")
      options = self.options.dup
      options[:padding] =
        Spacing.new(*(options.padding * 4).take(4).map(&:to_i))
      options[:margin] =
        Spacing.new(*(options.margin * 4).take(4).map(&:to_i))

      if file_path == ""
        file_path = "<stdin>"
        content = $stdin.read
        options[:output_path] = "stdin.mp4" if options.output_path.empty?
      else
        content = File.read(file_path)
      end

      Runner.new(file_path:, content:, thor: shell, options:).run
    end

    desc "themes", "Lists available built-in themes"
    def themes
      Dir[File.join(__dir__, "themes", "*.json")].each do |path|
        puts File.basename(path, ".json")
      end
    end

    no_commands do
      # Add helper methods here
    end
  end
end
