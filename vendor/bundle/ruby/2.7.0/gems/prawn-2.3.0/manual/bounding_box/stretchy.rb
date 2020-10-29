# frozen_string_literal: true

# Bounding Boxes accept an optional <code>:height</code> parameter. Unless it
# is provided the bounding box will be stretchy. It will expand the height to
# fit all content generated inside it.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  y_position = cursor
  bounding_box([0, y_position], width: 200, height: 100) do
    text 'This bounding box has a height of 100. If this text gets too large ' \
      'it will flow to the next page.'

    transparent(0.5) { stroke_bounds }
  end

  bounding_box([300, y_position], width: 200) do
    text 'This bounding box has variable height. No matter how much text is ' \
      'written here, the height will expand to fit.'

    text ' _' * 100

    text ' *' * 100

    transparent(0.5) { stroke_bounds }
  end
end
