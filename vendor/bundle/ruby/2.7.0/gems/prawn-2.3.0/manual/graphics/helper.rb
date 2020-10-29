# frozen_string_literal: true

# To produce this manual we use the <code>stroke_axis</code> helper method
# within the examples.
#
# <code>stroke_axis</code> prints the x and y axis for the current bounding box
# with markers in 100 increments. The defaults can be changed with various
# options.
#
# Note that the examples define a custom <code>:height</code> option so that
# only the example canvas is used (as seen with the output of the first line of
# the example code).

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  stroke_axis
  stroke_axis(
    at: [70, 70], height: 200, step_length: 50,
    negative_axes_length: 5, color: '0000FF'
  )
  stroke_axis(
    at: [140, 140], width: 200, height: cursor.to_i - 140,
    step_length: 20, negative_axes_length: 40, color: 'FF0000'
  )
end
