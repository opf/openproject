# frozen_string_literal: true

# This transformation is used to rotate the user space. Give it an angle
# and an <code>:origin</code> point about which to rotate and a block.
# Everything inside the block will be drawn with the rotated coordinates.
#
# The angle is in degrees.
#
# If you omit the <code>:origin</code> option the page origin will be used.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  stroke_axis

  fill_circle [250, 200], 2

  12.times do |i|
    rotate(i * 30, origin: [250, 200]) do
      stroke_rectangle [350, 225], 100, 50
      draw_text "Rotated #{i * 30}°", size: 10, at: [360, 205]
    end
  end
end
