# frozen_string_literal: true

# Note that because of the way PDF renders radial gradients in order to get
# solid fill your start circle must be fully inside your end circle.
# Otherwise you will get triangle fill like illustrated in the example below.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  self.line_width = 10

  # Linear Gradients
  fill_gradient [0, 250], [100, 150], 'ff0000', '0000ff'
  fill_rectangle [0, 250], 100, 100

  stroke_gradient [150, 150], [250, 250], '00ffff', 'ffff00'
  stroke_rectangle [150, 250], 100, 100

  fill_gradient [300, 250], [400, 150], 'ff0000', '0000ff'
  stroke_gradient [300, 150], [400, 250], '00ffff', 'ffff00'
  fill_and_stroke_rectangle [300, 250], 100, 100

  rotate 45, origin: [500, 200] do
    stops = { 0 => 'ff0000', 0.6 => '999900', 0.8 => '00cc00', 1 => '4444ff' }
    fill_gradient from: [460, 240], to: [540, 160], stops: stops
    fill_rectangle [460, 240], 80, 80
  end

  # Radial gradients
  fill_gradient [50, 50], 0, [50, 50], 70.71, 'ff0000', '0000ff'
  fill_rectangle [0, 100], 100, 100

  stroke_gradient [200, 50], 45, [200, 50], 70.71, '00ffff', 'ffff00'
  stroke_rectangle [150, 100], 100, 100

  stroke_gradient [350, 50], 45, [350, 50], 70.71, '00ffff', 'ffff00'
  fill_gradient [350, 50], 0, [350, 50], 70.71, 'ff0000', '0000ff'
  fill_and_stroke_rectangle [300, 100], 100, 100

  fill_gradient [500, 100], 50, [500, 0], 0, 'ff0000', '0000ff'
  fill_rectangle [450, 100], 100, 100
end
