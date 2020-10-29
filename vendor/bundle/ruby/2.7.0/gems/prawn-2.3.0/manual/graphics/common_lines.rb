# frozen_string_literal: true

# Prawn provides helpers for drawing some commonly used lines:
#
# <code>vertical_line</code> and <code>horizontal_line</code> do just what their
# names imply. Specify the start and end point at a fixed coordinate to define
# the line.
#
# <code>horizontal_rule</code> draws a horizontal line on the current bounding
# box from border to border, using the current y position.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  stroke_axis

  stroke_color 'ff0000'

  stroke do
    # just lower the current y position
    move_down 50
    horizontal_rule

    vertical_line   100, 300, at: 50

    horizontal_line 200, 500, at: 150
  end
end
