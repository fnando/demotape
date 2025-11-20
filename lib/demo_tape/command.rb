# frozen_string_literal: true

module DemoTape
  class Command
    KEY_MAPPING = {
      "Cancel" => :cancel,
      "Help" => :help,
      "Backspace" => :backspace,
      "Tab" => :tab,
      # "Clear" => :clear,
      "Return" => :return,
      "Enter" => :enter,
      "Shift" => :shift,
      "Control" => :control,
      "Ctrl" => :control,
      "Alt" => :alt,
      "Option" => :alt,
      "Pause" => :pause,
      "Escape" => :escape,
      "Esc" => :escape,
      "Space" => :space,
      "PageUp" => :page_up,
      "PageDown" => :page_down,
      "End" => :end,
      "Home" => :home,
      "Left" => :left,
      "Up" => :up,
      "Right" => :right,
      "Down" => :down,
      "Insert" => :insert,
      "Delete" => :delete,
      "Semicolon" => :semicolon,
      "Colon" => ":",
      "Equals" => :equals,
      "Numpad0" => :numpad0,
      "Numpad1" => :numpad1,
      "Numpad2" => :numpad2,
      "Numpad3" => :numpad3,
      "Numpad4" => :numpad4,
      "Numpad5" => :numpad5,
      "Numpad6" => :numpad6,
      "Numpad7" => :numpad7,
      "Numpad8" => :numpad8,
      "Numpad9" => :numpad9,
      "Multiply" => :multiply,
      "Add" => :add,
      "Separator" => :separator,
      "Subtract" => :subtract,
      "Decimal" => :decimal,
      "Divide" => :divide,
      "F1" => :f1,
      "F2" => :f2,
      "F3" => :f3,
      "F4" => :f4,
      "F5" => :f5,
      "F6" => :f6,
      "F7" => :f7,
      "F8" => :f8,
      "F9" => :f9,
      "F10" => :f10,
      "F11" => :f11,
      "F12" => :f12,
      "Meta" => :meta,
      "Command" => :command,
      "Slash" => "/",
      "BackSlash" => "\\"
    }.freeze

    VALID_COMMANDS = KEY_MAPPING.keys + %w[
      Clear
      Copy
      Group
      Include
      Output
      Pause
      Paste
      Require
      Resume
      Run
      Screenshot
      Send
      Set
      Sleep
      Type
      TypeFile
      Wait
      WaitUntil
    ].freeze

    META_COMMANDS = %w[Group Include Output Require Set].freeze
    COMMANDS_WITH_SPEED = KEY_MAPPING.keys + %w[Run Type TypeFile].freeze
    COMMANDS_WITH_TIMEOUT = %w[WaitUntil].freeze
    VALID_TIME_UNITS = %w[ms s m h].freeze

    # Valid keys that can be used in key combos
    VALID_KEYS = KEY_MAPPING.keys + %w[
      A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
      a b c d e f g h i j k l m n o p q r s t u v w x y z
      0 1 2 3 4 5 6 7 8 9
    ].freeze

    SET_OPTIONS = %w[
      border_radius cursor_blink cursor_style cursor_width font_family font_size
      height line_height loop loop_delay margin margin_fill padding shell theme
      typing_speed variable_typing width
    ].freeze

    attr_reader :type, :args, :options, :children
    attr_accessor :column, :duration_column, :file, :line, :line_content,
                  :speed_column, :timeout_column, :tokens

    def initialize(type, args = "", **options)
      @type = type
      @args = args
      @options = options
      @children = options.delete(:children) || []
      @group_invocation = options.delete(:group_invocation) || false
      @line = nil
      @column = nil
      @line_content = nil
      @file = nil
      @duration_column = nil
      @speed_column = nil
      @timeout_column = nil
      @tokens = []
    end

    # Whether this command represents a key press
    def key?
      VALID_KEYS.include?(type)
    end

    def group?
      type == "Group"
    end

    def keys
      return [] unless key?

      keys = [to_key_value(type)]
      keys += options.fetch(:keys, []).map { to_key_value(it) }

      keys
    end

    def to_key_value(input)
      KEY_MAPPING[input] || input.downcase
    end

    # Whether this command is a meta-command (i.e., not producing output)
    # Meta commands are executed before regular commands.
    def meta?
      META_COMMANDS.include?(type)
    end

    def to_sym
      @to_sym ||= type.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                      .tr("-", "_")
                      .downcase
                      .to_sym
    end

    def group_invocation?
      # Group invocations are marked as such
      # AND don't start with uppercase letter
      @group_invocation && type[0].to_s.match?(/[^A-Z]/)
    end

    def validate_command!
      return if group_invocation?
      return if VALID_COMMANDS.include?(type)

      raise_error "Unknown command: #{type.inspect}"
    end

    def validate_speed!
      return unless options[:speed] && !COMMANDS_WITH_SPEED.include?(type)

      raise_error "Command #{type.inspect} does not accept speed option"
    end

    def validate_timeout!
      return unless options[:timeout] && !COMMANDS_WITH_TIMEOUT.include?(type)

      raise_error "Command #{type.inspect} does not accept timeout option"
    end

    def validate_set_options!
      return unless type == "Set"

      # Handle nested options (e.g., theme.background)
      base_option = options[:option].split(".").first

      return if SET_OPTIONS.include?(base_option)

      raise_error "Unknown option: #{options[:option].inspect} #{self}",
                  column_override: tokens[2].column
    end

    def validate_keys!
      return unless options[:keys]

      all_keys = options[:keys] + [type]

      all_keys.each do |key|
        next if VALID_KEYS.include?(key)

        unless VALID_COMMANDS.include?(key)
          raise_error "Invalid key in combo: #{key.inspect}"
        end

        raise_error "Command #{key.inspect} doesn't support key combos"
      end
    end

    def validate_regex!
      return unless type == "WaitUntil"

      raise_error "WaitUntil command requires a regex pattern" if args.empty?

      begin
        options[:pattern] = Regexp.new(args)
      rescue RegexpError => error
        raise_error "Invalid regex pattern: #{error.message}"
      end
    end

    private def validate_children!
      return unless group?

      children.each do |child|
        next unless child.group?

        child.raise_error "Nested groups are not allowed"
      end
    end

    private def validate_type_file!
      return unless type == "TypeFile"

      raise_error "TypeFile command requires a file path" if args.empty?
    end

    private def validate_duration!
      [args, :duration] => [duration, source] if %w[Sleep Wait].include?(type)
      [options[:speed], :speed] => [duration, source] if options[:speed]
      [options[:timeout], :timeout] => [duration, source] if options[:timeout]

      return unless duration

      unit = duration[/[a-z]+$/i]
      return if VALID_TIME_UNITS.include?(unit)

      col = case source
            when :speed then speed_column
            when :timeout then timeout_column
            else duration_column
            end

      raise_error "Invalid time unit: #{unit.inspect}", column_override: col
    end

    def prepare!
      validate_command!
      validate_speed!
      validate_timeout!
      validate_children!
      normalize_theme_options!
      validate_set_options!
      validate_keys!
      validate_regex!
      validate_duration!
      validate_type_file!

      normalize_spacing_values!

      self
    end

    private def normalize_theme_options!
      return unless type == "Set"
      return unless options[:option]&.include?(".")

      option, sub_option = *options[:option].split(".", 2)

      unless option == "theme"
        raise_error "Unexpected attribute #{options[:option].inspect}",
                    column_override: tokens[2].column
      end

      unless Theme.valid_options.include?(sub_option.to_sym)
        raise_error "Invalid theme property",
                    column_override: tokens[2].column + option.length + 1 # option + "."
      end

      @options[:option] = option
      @options[:sub_option] = sub_option
    end

    private def normalize_spacing_values!
      return unless type == "Set"
      return unless %w[padding margin].include?(options[:option])

      @args = (Array(args).map(&:to_i) * 4).take(4)
    end

    def location(column_override: nil)
      col = column_override || column
      "#{file || '<unknown>'}:#{line}:#{col}"
    end

    def raise_error(message, column_override: nil)
      col = column_override || column

      raise DemoTape::ParseError, message unless line && col && line_content

      error_msg = "#{message} at #{location(column_override:)}:\n"
      error_msg += "  #{line_content.strip}\n"

      # Calculate pointer position: col is absolute position in original line
      # line_content.strip removes leading spaces, so we need to adjust
      leading_spaces = line_content[/^\s*/].length
      pointer_col = col - leading_spaces - 1
      error_msg += "  #{' ' * pointer_col}^"

      raise DemoTape::ParseError, error_msg
    end

    def to_s
      opts_str = options.empty? ? "" : " #{options.inspect}"
      "#{type} #{args.inspect}#{opts_str}"
    end

    def to_formatted(thor)
      return thor.set_color(type, :blue) unless tokens.any?

      values = []

      tokens.each_with_index do |token, index|
        previous_token = tokens[index - 1]
        preceded_by_number = previous_token.is_a?(Token::Number)

        case token
        when Token::String
          values << thor.set_color(token.raw, :yellow)
        when Token::Operator
          values << thor.set_color(token.value, :white)
        when Token::Number, Token::Duration
          values << thor.set_color(token.value, :magenta)
        when Token::Regex
          values << thor.set_color(token.raw, :green)
        when Token::Identifier
          values << thor.set_color(token.value, :blue)
        when Token::Space
          values << " " unless preceded_by_number
        when Token::Keyword
          values << thor.set_color(token.value, :cyan)
        else
          raise "Unexpected token type: #{token.class.name}"
        end
      end

      values.join.strip
    end
  end
end
