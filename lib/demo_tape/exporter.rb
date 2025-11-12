# frozen_string_literal: true

module DemoTape
  class Exporter
    attr_reader :tmp_dir, :frame_count, :options, :theme

    def initialize(tmp_dir:, frame_count:, options:, theme:)
      @tmp_dir = tmp_dir
      @frame_count = frame_count
      @options = options
      @theme = theme
    end

    def bounds
      @bounds ||= compute_image_bounds
    end

    def video(path)
      text_input = tmp_dir.join("frame-text-%05d.png")
      cursor_input = tmp_dir.join("frame-cursor-%05d.png")
      mask_path = tmp_dir.join("border-radius-mask.png")

      create_border_radius_mask(
        bounds.with_padding_width,
        bounds.with_padding_height,
        options.border_radius,
        mask_path
      )

      # Check if margin_fill is a file path
      if File.file?(options.margin_fill)
        # Use image as background
        filter = build_filter_with_image_background(bounds, mask_path)

        inputs = []
        inputs << "-framerate #{options.fps} -i #{text_input}"
        inputs << "-framerate #{options.fps} -i #{cursor_input}"
        inputs << "-loop 1 -i #{Shellwords.escape(options.margin_fill)}"
        inputs << "-loop 1 -i #{Shellwords.escape(mask_path)}"
      else
        # Use solid color as background
        filter = build_filter_with_color_background(bounds, mask_path)

        inputs = []
        inputs << "-framerate #{options.fps} -i #{text_input}"
        inputs << "-framerate #{options.fps} -i #{cursor_input}"
        inputs << "-loop 1 -i #{Shellwords.escape(mask_path)}"
      end

      cmd = <<~CMD
        ffmpeg -y \
          -loglevel error \
          #{inputs.join(" \\\n            ")} \
          -filter_complex "#{filter}" \
          -frames:v #{frame_count} \
          -c:v libx264 \
          -pix_fmt yuv420p \
          -r #{options.fps} \
          -movflags +faststart \
          #{Shellwords.escape(path)}
      CMD

      system(cmd)
    end

    def webm(path)
      text_input = tmp_dir.join("frame-text-%05d.png")
      cursor_input = tmp_dir.join("frame-cursor-%05d.png")

      # Always create border radius mask (square corners if radius is 0)
      mask_path = tmp_dir.join("border-radius-mask.png")
      create_border_radius_mask(
        bounds.with_padding_width,
        bounds.with_padding_height,
        options.border_radius,
        mask_path
      )

      # Check if margin_fill is a file path
      if File.file?(options.margin_fill)
        # Use image as background
        filter = build_filter_with_image_background(bounds, mask_path)

        inputs = []
        inputs << "-framerate #{options.fps} -i #{text_input}"
        inputs << "-framerate #{options.fps} -i #{cursor_input}"
        inputs << "-loop 1 -i #{Shellwords.escape(options.margin_fill)}"
        inputs << "-loop 1 -i #{Shellwords.escape(mask_path)}"
      else
        # Use solid color as background
        filter = build_filter_with_color_background(bounds, mask_path)

        inputs = []
        inputs << "-framerate #{options.fps} -i #{text_input}"
        inputs << "-framerate #{options.fps} -i #{cursor_input}"
        inputs << "-loop 1 -i #{Shellwords.escape(mask_path)}"
      end

      cmd = <<~CMD
        ffmpeg -y \
          -loglevel error \
          #{inputs.join(" \\\n            ")} \
          -filter_complex "#{filter}" \
          -frames:v #{frame_count} \
          -c:v libvpx-vp9 \
          -pix_fmt yuva420p \
          -b:v 0 \
          -crf 30 \
          -r #{options.fps} \
          #{Shellwords.escape(path)}
      CMD

      system(cmd)
    end

    def gif(path)
      text_input = tmp_dir.join("frame-text-%05d.png")
      cursor_input = tmp_dir.join("frame-cursor-%05d.png")
      loop_flag = options.loop ? "-loop 0" : "-loop -1"

      # Always create border radius mask (square corners if radius is 0)
      mask_path = tmp_dir.join("border-radius-mask.png")
      create_border_radius_mask(
        bounds.with_padding_width,
        bounds.with_padding_height,
        options.border_radius,
        mask_path
      )

      # Check if margin_fill is a file path
      if File.file?(options.margin_fill)
        # Use image as background
        filter = build_filter_with_image_background(bounds, mask_path)

        inputs = []
        inputs << "-framerate #{options.fps} -i #{text_input}"
        inputs << "-framerate #{options.fps} -i #{cursor_input}"
        inputs << "-loop 1 -i #{Shellwords.escape(options.margin_fill)}"
        inputs << "-loop 1 -i #{Shellwords.escape(mask_path)}"
      else
        # Use solid color as background
        filter = build_filter_with_color_background(bounds, mask_path)

        inputs = []
        inputs << "-framerate #{options.fps} -i #{text_input}"
        inputs << "-framerate #{options.fps} -i #{cursor_input}"
        inputs << "-loop 1 -i #{Shellwords.escape(mask_path)}"
      end

      filter = apply_gif_loop_delay(filter)
      total_frames = calculate_gif_total_frames

      cmd = <<~CMD
        ffmpeg -y \
          -loglevel error \
          #{inputs.join(" \\\n            ")} \
          -filter_complex "#{filter}" \
          -frames:v #{total_frames} \
          #{loop_flag} \
          -r #{options.fps} \
          #{Shellwords.escape(path)}
      CMD

      system(cmd)
    end

    def png(path)
      text_input = tmp_dir.join(format("frame-text-%05d.png", frame_count))
      cursor_input = tmp_dir.join(format("frame-cursor-%05d.png", frame_count))

      # Always create border radius mask (square corners if radius is 0)
      mask_path = tmp_dir.join("border-radius-mask.png")
      create_border_radius_mask(
        bounds.with_padding_width,
        bounds.with_padding_height,
        options.border_radius,
        mask_path
      )

      # Check if margin_fill is a file path
      if File.file?(options.margin_fill)
        # Use image as background
        filter = build_filter_with_image_background(bounds, mask_path)

        inputs = []
        inputs << "-i #{Shellwords.escape(text_input.to_s)}"
        inputs << "-i #{Shellwords.escape(cursor_input.to_s)}"
        inputs << "-i #{Shellwords.escape(options.margin_fill)}"
        inputs << "-i #{Shellwords.escape(mask_path)}"
      else
        # Use solid color as background
        filter = build_filter_with_color_background(bounds, mask_path)

        inputs = []
        inputs << "-i #{Shellwords.escape(text_input.to_s)}"
        inputs << "-i #{Shellwords.escape(cursor_input.to_s)}"
        inputs << "-i #{Shellwords.escape(mask_path)}"
      end

      cmd = <<~CMD
        ffmpeg -y \
          -loglevel error \
          #{inputs.join(" \\\n            ")} \
          -filter_complex "#{filter}" \
          -frames:v 1 \
          #{Shellwords.escape(path)}
      CMD

      system(cmd)
    end

    def get_png_dimensions(file_path)
      File.open(file_path, "rb") do |f|
        f.read(8)  # Skip PNG signature
        f.read(4)  # Skip chunk length
        f.read(4)  # Skip "IHDR"
        width = f.read(4).unpack1("N")   # Read width (big-endian)
        height = f.read(4).unpack1("N")  # Read height (big-endian)
        [width, height]
      end
    end

    def compute_image_bounds
      first_frame = tmp_dir.glob("frame-text-*.png").first
      actual_width, actual_height = get_png_dimensions(first_frame)
      padding = options.padding
      margin = options.margin

      # options.width and options.height are the FINAL output dimensions
      # We need to work backwards: final size includes margin
      final_width = options.width
      final_height = options.height

      # Calculate how much space is available for padding area
      # (after subtracting margin)
      available_for_padding_width = final_width - margin.left - margin.right
      available_for_padding_height = final_height - margin.top - margin.bottom

      # Calculate content width/height with user-specified padding
      content_width = actual_width + padding.left + padding.right
      content_height = actual_height + padding.top + padding.bottom

      # Any additional space needed goes to right and bottom
      extra_width = [0, available_for_padding_width - content_width].max
      extra_height = [0, available_for_padding_height - content_height].max

      # Dimensions after padding is applied
      # (fits within available space after margin)
      with_padding_width = content_width + extra_width
      with_padding_height = content_height + extra_height

      Bounds.new(
        padding_left: padding.left,
        padding_top: padding.top,
        with_padding_width:,
        with_padding_height:,
        margin_left: margin.left,
        margin_top: margin.top,
        with_margin_width: final_width,
        with_margin_height: final_height
      )
    end

    def build_filter_with_image_background(bounds, _mask_path)
      # Input 0: text frames
      # Input 1: cursor frames
      # Input 2: background image
      # Input 3: mask

      # Scale background to output size and center/crop if needed
      filter = "[2:v]scale=#{bounds.with_margin_width}:#{bounds.with_margin_height}:force_original_aspect_ratio=increase,crop=#{bounds.with_margin_width}:#{bounds.with_margin_height}[bg];" # rubocop:disable Layout/LineLength

      # Overlay text+cursor, add padding
      filter += "[0:v][1:v]overlay=0:0"
      filter += ",pad=#{bounds.with_padding_width}:#{bounds.with_padding_height}:#{bounds.padding_left}:#{bounds.padding_top}:#{theme.background}" # rubocop:disable Layout/LineLength

      # Apply border radius mask
      filter += "[term];[3]loop=-1[mask];[term][mask]alphamerge[terminal];"

      # Overlay terminal on background, centered
      filter += "[bg][terminal]overlay=(W-w)/2:(H-h)/2"
      filter
    end

    def build_filter_with_color_background(bounds, _mask_path)
      # Overlay text+cursor, add padding, then add margin
      filter = "[0:v][1:v]overlay=0:0"
      filter += ",pad=#{bounds.with_padding_width}:#{bounds.with_padding_height}:#{bounds.padding_left}:#{bounds.padding_top}:#{theme.background}" # rubocop:disable Layout/LineLength

      # Apply border radius mask
      filter += "[term];[2]loop=-1[mask];[term][mask]alphamerge"

      filter += ",pad=#{bounds.with_margin_width}:#{bounds.with_margin_height}:#{bounds.margin_left}:#{bounds.margin_top}:#{options.margin_fill}" # rubocop:disable Layout/LineLength
      filter
    end

    def create_border_radius_mask(width, height, radius, path)
      # Ensure radius is non-negative
      radius = [0, radius.to_i].max

      # Create a grayscale image for the alpha mask
      img = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::BLACK)

      if radius.zero?
        # No border radius - just fill everything white
        (0...height).each do |y|
          (0...width).each do |x|
            img[x, y] = ChunkyPNG::Color::WHITE
          end
        end
      else
        # Draw a white rounded rectangle
        # Fill the main rectangle
        (radius...(height - radius)).each do |y|
          (0...width).each do |x|
            img[x, y] = ChunkyPNG::Color::WHITE
          end
        end

        (0...height).each do |y|
          (radius...(width - radius)).each do |x|
            img[x, y] = ChunkyPNG::Color::WHITE
          end
        end

        # Draw the four rounded corners
        draw_rounded_corner(img, radius, radius, radius)
        draw_rounded_corner(img, width - radius - 1, radius, radius)
        draw_rounded_corner(img, radius, height - radius - 1, radius)
        draw_rounded_corner(img, width - radius - 1, height - radius - 1,
                            radius)
      end

      img.save(path)
    end

    def draw_rounded_corner(img, cx, cy, radius)
      (-radius..radius).each do |dy|
        (-radius..radius).each do |dx|
          dist_sq = (dx * dx) + (dy * dy)
          next unless dist_sq <= (radius + 1) * (radius + 1)

          x = cx + dx
          y = cy + dy
          if x.negative? || x >= img.width || y.negative? || y >= img.height
            next
          end

          img[x, y] = ChunkyPNG::Color::WHITE
        end
      end
    end

    def apply_gif_loop_delay(filter)
      delay = Duration.parse(options.loop_delay)

      return filter unless delay.positive?

      delay_frames = (delay * options.fps).ceil
      "#{filter},tpad=stop_mode=clone:stop_duration=#{delay_frames}"
    end

    def calculate_gif_total_frames
      delay = Duration.parse(options.loop_delay)

      return frame_count unless delay.positive?

      delay_frames = (delay * options.fps).ceil
      frame_count + delay_frames
    end
  end
end
