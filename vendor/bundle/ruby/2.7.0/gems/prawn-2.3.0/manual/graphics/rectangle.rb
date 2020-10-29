# frozen_string_literal: true

# To draw a rectangle, just provide the upper-left corner, width and height to
# the <code>rectangle</code> method.
#
# There's also <code>rounded_rectangle</code>. Just provide an additional radius
# value for the rounded corners.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  stroke_axis

  stroke do
    rectangle [100, 300], 100, 200

    rounded_rectangle [300, 300], 100, 200, 20
  end
end
