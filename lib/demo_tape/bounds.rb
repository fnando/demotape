# frozen_string_literal: true

module DemoTape
  Bounds = Struct.new(
    :padding_left,
    :padding_top,
    :with_padding_width,
    :with_padding_height,
    :margin_left,
    :margin_top,
    :with_margin_width,
    :with_margin_height,
    keyword_init: true
  )
end
