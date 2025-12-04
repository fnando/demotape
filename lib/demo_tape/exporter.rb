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

    def ffmpeg_settings(single_frame: false)
      if single_frame
        frame_input = tmp_dir.join(format("frame-%05d.png", frame_count))
      else
        frame_input = tmp_dir.join("frame-%05d.png")
      end

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
        if single_frame
          inputs << "-i #{Shellwords.escape(frame_input.to_s)}"
          inputs << "-i #{Shellwords.escape(options.margin_fill)}"
          inputs << "-i #{Shellwords.escape(mask_path)}"
        else
          inputs << "-framerate #{options.fps} -i #{frame_input}"
          inputs << "-loop 1 -i #{Shellwords.escape(options.margin_fill)}"
          inputs << "-loop 1 -i #{Shellwords.escape(mask_path)}"
        end
      else
        # Use solid color as background
        filter = build_filter_with_color_background(bounds, mask_path)

        inputs = []
        if single_frame
          inputs << "-i #{Shellwords.escape(frame_input.to_s)}"
          inputs << "-i #{Shellwords.escape(mask_path)}"
        else
          inputs << "-framerate #{options.fps} -i #{frame_input}"
          inputs << "-loop 1 -i #{Shellwords.escape(mask_path)}"
        end
      end

      {inputs:, filter:}
    end

    def video(path)
      ffmpeg_settings => {inputs:, filter:}

      encoder = if File.extname(path).downcase == ".avi"
                  "-c:v ffv1"
                else
                  "-c:v libx264 -crf 0 -pix_fmt yuv444p"
                end

      cmd = <<~CMD
        ffmpeg -y \
          -loglevel error \
          #{inputs.join(" \\\n            ")} \
          -filter_complex "#{filter}" \
          -frames:v #{frame_count} \
          -r #{options.fps} \
          #{encoder} \
          #{Shellwords.escape(path)}
      CMD

      system(cmd)
    end

    def webm(path)
      ffmpeg_settings => {inputs:, filter:}

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
      ffmpeg_settings => {inputs:, filter:}
      loop_flag = options.loop ? "-loop 0" : "-loop -1"

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
      ffmpeg_settings(single_frame: true) => {inputs:, filter:}

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
      return [0, 0] unless file_path
      return [0, 0] unless File.file?(file_path)

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
      first_frame = tmp_dir.glob("frame-*.png").first
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
      # Input 0: combined frame (text + cursor)
      # Input 1: background image
      # Input 2: mask

      # Scale background to output size and center/crop if needed
      filter = "[1:v]scale=#{bounds.with_margin_width}:#{bounds.with_margin_height}:force_original_aspect_ratio=increase,crop=#{bounds.with_margin_width}:#{bounds.with_margin_height}[bg];" # rubocop:disable Layout/LineLength

      # Add padding to frame
      filter += "[0:v]pad=#{bounds.with_padding_width}:#{bounds.with_padding_height}:#{bounds.padding_left}:#{bounds.padding_top}:#{theme.background}" # rubocop:disable Layout/LineLength

      # Apply border radius mask
      filter += "[term];[2]loop=-1[mask];[term][mask]alphamerge[terminal];"

      # Overlay terminal on background, centered
      filter += "[bg][terminal]overlay=(W-w)/2:(H-h)/2"
      filter
    end

    def build_filter_with_color_background(bounds, _mask_path)
      # Input 0: combined frame (text + cursor)
      # Input 1: mask

      # Add padding to frame
      filter = "[0:v]pad=#{bounds.with_padding_width}:#{bounds.with_padding_height}:#{bounds.padding_left}:#{bounds.padding_top}:#{theme.background}" # rubocop:disable Layout/LineLength

      # Apply border radius mask
      filter += "[term];[1]loop=-1[mask];[term][mask]alphamerge"

      # Add margin
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
