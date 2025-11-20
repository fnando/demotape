# frozen_string_literal: true

module DemoTape
  class Runner
    attr_reader :file_path, :content, :options, :tmp_dir, :state_mutex,
                :session_mutex, :threads, :state, :thor,
                :unnamed_screenshot_count, :output_paths
    attr_accessor :screenshot_count

    def initialize(file_path:, content:, thor:, options:)
      @file_path = file_path
      @content = content
      @options = options
      @tmp_dir = Pathname.mktmpdir
      @state_mutex = Mutex.new
      @state = {
        keep_recording: true,
        paused: true,
        term_current_line: {number: 0, content: ""},
        clipboard: "",
        current_frame: 1
      }
      @session_mutex = Mutex.new
      @threads = []
      @thor = thor
      @screenshot_count = 0
    end

    def ttyd
      @ttyd ||= TTYD.new(port: options.port, shell: options.shell)
    end

    def fail_with(message)
      thor.say_error "\nERROR: #{message}", :red
      exit 1
    end

    def validate_ttyd
      return if system("which ttyd > /dev/null 2>&1")

      fail_with "ttyd is not installed or not found in PATH."
    end

    def validate_ffmpeg
      return if system("which ffmpeg > /dev/null 2>&1")

      fail_with "ffmpeg is not installed or not found in PATH."
    end

    def preflight_checks
      validate_ttyd
      validate_ffmpeg
    end

    def debug(message)
      return unless options.debug

      thor.say_status :debug, message, :red
    end

    def clock_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def commands
      @commands ||= begin
        debug "Parsing tape"
        Parser.new.parse(content, file: file_path)
      end
    end

    def meta_commands
      commands.select(&:meta?)
    end

    def groups
      @groups ||=
        commands
        .select(&:group?)
        .each_with_object({}) do |command, buffer|
          buffer[command.args] = command
        end
    end

    def executable_commands
      commands.reject(&:meta?)
    end

    def resolve_group_expansions
      @commands = commands.flat_map do |command|
        next command unless command.group_invocation?

        group = groups[command.type]

        unless group
          command.raise_error("Undefined group: #{command.type.inspect}")
        end

        group.children
      end
    end

    def resolve_includes
      nested_level = 0

      while commands.any? { it.type == "Include" }
        fail_with "Maximum include nesting level exceeded" if nested_level > 10

        @commands = commands.flat_map do |command|
          if command.type == "Include"
            nested_level += 1
            thor.say_status :command, command.to_formatted(thor)
            Parser.new.parse(File.read(command.args), file: command.args)
          else
            command
          end
        end
      end
    end

    def run_meta_commands
      debug "Running meta commands"
      meta_commands.each { run_command(it) }
    end

    def start_ttyd
      ttyd_url = "http://127.0.0.1:#{ttyd.port}"
      debug "Starting ttyd at #{thor.set_color(ttyd_url, :blue)}"
      ttyd.start

      session_mutex.synchronize do
        debug "Visiting ttyd url"
        session.visit(ttyd.url)
      end

      textarea
      text_canvas
      cursor_canvas
    end

    def send_ttyd_options
      debug "Setting term options"
      session.execute_script("term.options = #{ttyd_options}; term.fit();")
    end

    def resolve_screenshot_count
      @unnamed_screenshot_count = commands.count do |command|
        command.type == "Screenshot" && command.args.empty?
      end
    end

    def resolve_output_paths
      @output_paths = options.output_path.map { Pathname.new(it) }

      return unless output_paths.empty?

      output_paths << Pathname.new(file_path).sub_ext(".mp4")
    end

    def run
      Thread.abort_on_exception = true
      Capybara.default_driver = :selenium_chrome_headless

      write_state(:started, clock_time)
      thor.say_status :info,
                      "Running #{thor.set_color(file_path, :blue)}"
      thor.say_status :info, "Using #{thor.set_color(options.shell, :blue)}"
      debug "Running preflight checks"
      preflight_checks

      resolve_includes
      if options.screenshot
        commands << Command.new("Screenshot", "",
                                tokens: [Token::Identifier.new("Screenshot")])
      end

      resolve_screenshot_count
      resolve_group_expansions
      run_meta_commands
      resolve_output_paths
      setup_tmp_dir
      start_ttyd
      resize_browser_window
      send_ttyd_options

      threads << recorder
      threads << executor(commands)
      threads.each(&:join)

      generate_output
      elapsed = format("%.2fs", clock_time - read_state(:started))
      thor.say_status :info,
                      "Finished in #{thor.set_color(elapsed, :blue)}"
    rescue StandardError => error
      write_state(:keep_recording, false)
      write_state(:paused, true)
      fail_with error.message
    ensure
      FileUtils.rm_rf(tmp_dir)
      ttyd.stop
    end

    def ttyd_options
      JSON.dump(
        fontSize: options.font_size,
        fontFamily: options.font_family,
        letterSpacing: options.letter_spacing,
        lineHeight: options.line_height,
        cursorBlink: options.cursor_blink,
        cursorStyle: options.cursor_style,
        cursorWidth: options.cursor_width,
        theme:,
        rendererType: "canvas",
        disableResizeOverlay: true,
        enableSixel: true,
        customGlyphs: true
      )
    end

    def find_theme
      [
        Pathname.new(options.theme),
        Pathname.new(__dir__).join("themes/#{options.theme}.json"),
        Pathname.new(__dir__).join("themes/default_dark.json")
      ].find(&:file?)
    end

    def theme
      @theme ||= Theme.new(**JSON.parse(find_theme.read, symbolize_names: true))
    end

    def read_state(key)
      state_mutex.synchronize { state.fetch(key) }
    end

    def write_state(key, value)
      state_mutex.synchronize { state[key] = value }
    end

    def setup_tmp_dir
      debug "Setting up tmp dir"
      tmp_dir.mkpath unless tmp_dir.exist?
    end

    def session
      @session ||= Capybara::Session.new(:selenium_chrome_headless)
    end

    def textarea
      @textarea ||= session_mutex.synchronize do
        session.find("textarea", visible: false, wait: 10)
      end
    end

    def text_canvas
      @text_canvas ||= session_mutex.synchronize do
        session.find("canvas.xterm-text-layer", wait: 10)
      end
    end

    def cursor_canvas
      @cursor_canvas ||= session_mutex.synchronize do
        session.find("canvas.xterm-cursor-layer", wait: 10)
      end
    end

    def resize_browser_window
      padding = options.padding
      margin = options.margin
      win_width = options.width -
                  (padding.left + padding.right) -
                  (margin.left + margin.right)
      win_height = options.height -
                   (padding.top + padding.bottom) -
                   (margin.top + margin.bottom)

      debug "Resizing browser window to " \
            "#{thor.set_color("#{win_width}x#{win_height}", :blue)}"
      debug "Padding - top: #{options.padding.top}, " \
            "right: #{options.padding.right}, " \
            "bottom: #{options.padding.bottom}, " \
            "left: #{options.padding.left}"
      debug "Margin - top: #{options.margin.top}, " \
            "right: #{options.margin.right}, " \
            "bottom: #{options.margin.bottom}, " \
            "left: #{options.margin.left}"

      # Resize to desired dimensions
      session.driver.browser.manage.window.resize_to(win_width, win_height)

      # Check actual viewport size and adjust if needed, due to
      # Chrome's internal overhead
      viewport = session.evaluate_script(
        "({ width: window.innerWidth, height: window.innerHeight })"
      )
      chrome_overhead_width = win_width - viewport["width"]
      chrome_overhead_height = win_height - viewport["height"]

      return unless chrome_overhead_width != 0 || chrome_overhead_height != 0

      debug "Chrome overhead detected: " \
            "#{thor.set_color(
              "#{chrome_overhead_width}x#{chrome_overhead_height}", :yellow
            )}"
      adjusted_width = win_width + chrome_overhead_width
      adjusted_height = win_height + chrome_overhead_height
      debug "Adjusting to: #{thor.set_color(
        "#{adjusted_width}x#{adjusted_height}", :blue
      )}"
      session.driver.browser.manage.window.resize_to(adjusted_width,
                                                     adjusted_height)
    end

    def capture_script
      @capture_script ||= <<~SCRIPT
        [
          arguments[0].toDataURL('image/png'),
          arguments[1].toDataURL('image/png')
        ]
      SCRIPT
    end

    def capture(frame)
      text_data = nil
      cursor_data = nil

      session_mutex.synchronize do
        text_data, cursor_data =
          *session.evaluate_script(capture_script, text_canvas, cursor_canvas)
      end

      text_png = Base64
                 .decode64(text_data.sub(%r{^data:image/png;base64,}, ""))
      cursor_png = Base64
                   .decode64(cursor_data.sub(%r{^data:image/png;base64,}, ""))
      frame_with_pad = format("%05d", frame)

      tmp_dir.join("frame-text-#{frame_with_pad}.png").binwrite(text_png)
      tmp_dir.join("frame-cursor-#{frame_with_pad}.png").binwrite(cursor_png)
    end

    def generate_output
      return if options.screenshot_only

      frame_count = read_state(:current_frame)
      exporter = Exporter.new(tmp_dir:, frame_count:, options:, theme:)

      output_paths.each do |path|
        if path.exist? && !options.overwrite
          fail_with "Output file already exists: #{path}"
        end

        thor.say_status :output,
                        "Generating #{thor.set_color(path, :blue)}"

        spinner = Spinner.new(phrases: [
          "Processing the frames…",
          "Encoding the video…",
          "Finalizing the output…",
          "Almost there…",
          "Wrapping things up…"
        ])

        case path.extname.downcase
        when ".gif"
          exporter.gif(path)
        when ".webm"
          exporter.webm(path)
        else
          exporter.video(path)
        end

        spinner.stop
      end
    end

    def run_command(command)
      thor.say_status :command, command.to_formatted(thor)

      name = if command.key?
               :type_key
             else
               command.to_sym
             end

      started = clock_time
      public_send("run_#{name}", command)
      elapsed = format("%.2fs", clock_time - started)
      debug thor.set_color("Executed in #{elapsed}", :white)
    end

    def executor(_commands)
      default_rc_path = File.join(__dir__, "rcs", options.shell)

      if options.rc_file && !File.file?(options.rc_file)
        fail_with "Custom rc file not found: " \
                  "#{thor.set_color(options.rc_file, :blue)}"
      end

      debug "Executing commands"

      Thread.new do
        Thread.current.report_on_exception = false

        unless options.no_rc
          debug "Loading default rc for #{options.shell} from " \
                "#{thor.set_color(default_rc_path, :blue)}"
          send_keys(
            %[source "#{default_rc_path}"; echo "::demotape:ready::"],
            "\n"
          )
        end

        if options.rc_file
          debug "Loading custom rc for #{options.shell} from " \
                "#{thor.set_color(options.rc_file, :blue)}"
          send_keys(
            %[source "#{default_rc_path}"; echo "::demotape:ready::"],
            "\n"
          )
        end

        run_wait_until(
          Command.new("WaitUntil", "", pattern: /^::demotape:ready::$/)
        )
        run_clear(nil)
        sleep 1

        # Start unpaused unless the first command is Pause
        first_command = executable_commands.first
        write_state(:paused, first_command&.type == "Pause")

        executable_commands.each do |command|
          run_command(command)
          write_state(:term_current_line, term_current_line)
        end
      ensure
        write_state(:keep_recording, false)
      end
    end

    def term_current_line
      session_mutex.synchronize do
        script = <<~SCRIPT
          (() => {
            const lineNum = term.buffer.active.cursorY + term.buffer.active.viewportY;
            const content = term.buffer.active.getLine(lineNum).translateToString().trimEnd();
            return { number: lineNum, content: content };
          })()
        SCRIPT

        session.evaluate_script(script).transform_keys(&:to_sym)
      end
    end

    def recorder
      target_fps = options.fps
      target_interval = (1.0 / target_fps)
      tick = target_interval - 0.02
      debug "Starting recorder"

      Thread.new do
        Thread.current.report_on_exception = false

        loop do
          keep_recording = read_state(:keep_recording)
          paused = read_state(:paused)
          current_frame = read_state(:current_frame)

          break unless keep_recording

          if paused
            sleep tick
            next
          end

          started = clock_time
          capture(current_frame)
          elapsed = clock_time - started

          tick = (1.0 / target_fps) - elapsed if current_frame == 2
          write_state(:current_frame, current_frame + 1)

          sleep tick if tick.positive?
        end
      end
    end

    def send_keys(*keys)
      # Check if any string key contains characters outside BMP
      has_non_bmp = keys.any? do |key|
        key.is_a?(String) && key.chars.any? {|c| c.ord > 0xFFFF }
      end

      session_mutex.synchronize do
        if has_non_bmp
          # Send each key individually if we have non-BMP characters
          keys.each do |key|
            if key.is_a?(String) && key.chars.any? {|c| c.ord > 0xFFFF }
              send_keys_via_js(key)
            else
              textarea.send_keys(key)
            end
          end
        else
          # Send all keys at once (preserves chord behavior like Ctrl+L)
          textarea.send_keys(keys)
        end
      end
    end

    def send_keys_via_js(text)
      # Escape the text for JavaScript
      escaped = JSON.dump(text)

      # Use xterm.js to write directly to the terminal
      script = "term.paste(#{escaped});"
      session.execute_script(script)
    end

    def run_wait_until(command)
      timeout = Duration.parse(command.options.fetch(:duration, 15))
      tick = 0.02

      curr_line = read_state(:term_current_line)
      offset = curr_line[:number].to_i
      lines = []

      spinner = Spinner.new(phrases: [
        "Searching high and low…",
        "Looking under every byte…",
        "Hunting for the pattern…",
        "Scanning the output stream…",
        "Seeking the needle in the haystack…"
      ])

      while timeout.positive?
        session_mutex.synchronize do
          script = <<~SCRIPT
            (() => {
              let linesCount = term.buffer.active.length;
              let lines = [];

              for (let lineNumber = #{offset}; lineNumber < linesCount; lineNumber += 1) {
                lines.push(term.buffer.active.getLine(lineNumber).translateToString().trimEnd());
              }

              return lines;
            })()
          SCRIPT

          lines = session.evaluate_script(script)
        end

        matches = lines.grep(command.options[:pattern])

        if matches.any?
          spinner.stop
          return
        end

        timeout -= tick
        sleep tick
      end

      spinner.stop
      command.raise_error("Timeout")
    end

    def run_type(command)
      speed = Duration.parse(
        command.options.fetch(:duration, options.typing_speed)
      )

      text_size = command.args.chars.count
      estimated_time = speed * text_size
      variable_typing = options.variable_typing || 0.0

      if estimated_time > 1.0
        spinner = Spinner.new(phrases: [
          "Typing this up…",
          "Writing this now…",
          "Typing away here…"
        ])
      end

      command.args.each_char do |char|
        adjusted_speed =
          speed + rand(-(speed * variable_typing)..(speed * variable_typing))

        sleep(adjusted_speed)
        send_keys(char)
      end

      spinner&.stop
      sleep(speed)
    end

    def run_wait(command)
      spinner = Spinner.new(phrases: [
        "Waiting a bit…",
        "Taking a short break…",
        "Pausing for a moment…",
        "Holding on briefly…",
        "Just a quick wait…"
      ])

      sleep(Duration.parse(command.args))

      spinner.stop
    end
    alias run_sleep run_wait

    def run_require(command)
      return if find_executable(command.args)

      command.raise_error("#{command.args.inspect} couldn't be found")
    end

    def run_type_key(command)
      speed = Duration.parse(
        command.options.fetch(:duration, options.typing_speed)
      )

      command.options.fetch(:count, 1).times do
        send_keys(*command.keys)
        sleep(speed)
      end
    end

    def run_copy(command)
      write_state(:clipboard, command.args)
    end

    def run_paste(_command)
      send_keys(read_state(:clipboard))
    end

    def run_pause(_command)
      write_state(:paused, true)
    end

    def run_send(command)
      send_keys(command.args)
    end

    def run_resume(_command)
      write_state(:paused, false)
    end

    def run_set(command)
      name = command.options[:option].to_sym
      value = command.args

      if %i[font_size height width cursor_width].include?(name)
        value = value.to_i
      end

      value = value.to_f if %i[line_height variable_typing].include?(name)
      value = value == "true" if %i[cursor_blink loop].include?(name)

      if %i[margin padding].include?(name)
        value = Spacing.new(*(Array(value) * 4).take(4).map(&:to_i))
      end

      if name == :theme
        if command.options[:sub_option]
          theme[command.options[:sub_option].to_sym] = value
          return
        else
          @theme = nil
        end
      end

      options[name] = value
    end

    def run_output(command)
      options.output_path << command.args
    end

    def run_clear(_command)
      session_mutex.synchronize do
        session.execute_script("term.clear();")
      end

      send_keys(:control, "l")
      run_wait(Command.new("Wait", "", duration: 0.5))
    end

    def run_run(command)
      run_type(Command.new("Type", command.args))
      run_wait(Command.new("Wait", "", duration: options.run_enter_delay))
      send_keys(:enter)
      run_wait(Command.new("Wait", "", duration: options.run_sleep))
    end

    def run_type_file(command)
      unless File.file?(command.args)
        command.raise_error("File not found",
                            column_override: command.tokens.last.column)
      end

      content = File.read(command.args)
      run_type(Command.new("Type", content, *command.options))
    end

    def run_group(*)
      # do nothing
    end

    def run_screenshot(command)
      exporter = Exporter.new(
        tmp_dir:,
        frame_count: read_state(:current_frame),
        options:,
        theme:
      )

      screenshot_paths = [command.args].flatten.reject(&:empty?)

      if screenshot_paths.empty?
        screenshot_paths = output_paths.map do |path|
          ext = if unnamed_screenshot_count > 1
                  pad = [unnamed_screenshot_count.to_s.size, 2].max
                  format("-%s.png", format("%0#{pad}d", screenshot_count))
                else
                  ".png"
                end

          Pathname.new(path).sub_ext(ext)
        end

        self.screenshot_count += 1
      end

      screenshot_paths.uniq { it.expand_path.to_s }.each do |screenshot_path|
        exporter.png(screenshot_path)
        path = thor.set_color(Shellwords.escape(screenshot_path.to_s), :magenta)
        thor.say_status :screenshot, "Saved to #{path}"
      end
    end

    def find_executable(name)
      exts = ENV["PATHEXT"] ? ENV["PATHEXT"].split(";") : [""]

      ENV["PATH"].split(File::PATH_SEPARATOR).each do |dir|
        exts.each do |ext|
          exe = File.join(dir, name + ext)
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end

      nil
    end
  end
end
