# frozen_string_literal: true

# Prawn supports drawing both lines and curves starting either at the current
# position, or from a specified starting position.
#
# <code>line_to</code> and <code>curve_to</code> set the drawing path from the
# current drawing position to the specified point. The initial drawing position
# can be set with <code>move_to</code>. They are useful when you want to chain
# successive calls because the drawing position will be set to the specified
# point afterwards.
#
# <code>line</code> and <code>curve</code> set the drawing path between the two
# specified points.
#
# Both curve methods define a Bezier curve bounded by two aditional points
# provided as the <code>:bounds</code> param.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  stroke_axis

  # line_to and curve_to
  stroke do
    move_to 0, 0

    line_to 100, 100
    line_to 0, 100

    curve_to [150, 250], bounds: [[20, 200], [120, 200]]
    curve_to [200, 0],   bounds: [[150, 200], [450, 10]]
  end

  # line and curve
  stroke do
    line [300, 200], [400, 50]
    curve [500, 0], [400, 200], bounds: [[600, 300], [300, 390]]
  end
end
