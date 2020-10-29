# frozen_string_literal: true

# Rotating text is best avoided on free flowing text, so this example
# will only use the <code>text_box</code> method as we can have much more
# control over its output.
#
# To rotate text all we need to do is use the <code>:rotate</code> option
# passing an angle in degrees and an optional <code>:rotate_around</code> to
# indicate the origin of the rotation (the default is <code>:upper_left</code>).

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  width = 100
  height = 60
  angle = 30
  x = 200
  y = cursor - 30

  stroke_rectangle [0, y], width, height
  text_box(
    'This text was not rotated',
    at: [0, y], width: width, height: height
  )

  stroke_rectangle [0, y - 100], width, height
  text_box(
    'This text was rotated around the center',
    at: [0, y - 100], width: width, height: height,
    rotate: angle, rotate_around: :center
  )

  %i[lower_left upper_left lower_right upper_right]
    .each_with_index do |corner, index|
    y -= 100 if index == 2
    stroke_rectangle [x + (index % 2) * 200, y], width, height
    text_box(
      "This text was rotated around the #{corner} corner.",
      at: [x + (index % 2) * 200, y],
      width: width,
      height: height,
      rotate: angle,
      rotate_around: corner
    )
  end
end
