# frozen_string_literal: true

# This transformation is used to translate the user space. Just provide the
# x and y coordinates for the new origin.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  stroke_axis

  1.upto(3) do |i|
    x = i * 50
    y = i * 100
    translate(x, y) do
      # Draw a point on the new origin
      fill_circle [0, 0], 2
      draw_text "New origin after translation to [#{x}, #{y}]",
        at: [5, -2], size: 8

      stroke_rectangle [100, 75], 100, 50
      text_box 'Top left corner at [100,75]',
        at: [110, 65],
        width: 80,
        size: 8
    end
  end
end
