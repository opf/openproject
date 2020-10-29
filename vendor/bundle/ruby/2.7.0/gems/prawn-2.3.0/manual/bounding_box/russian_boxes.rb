# frozen_string_literal: true

# This example is mostly just for fun, and shows how nested bounding boxes
# can simplify calculations. See the "Bounding Box" section of the manual
# for more basic uses.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  def combine(horizontal_span, vertical_span)
    output = []
    horizontal_span.each do |x|
      vertical_span.each do |y|
        output += [[x, y]]
      end
    end
    output
  end

  def recurse_bounding_box(max_depth = 4, depth = 1)
    width = (bounds.width - 15) / 2
    height = (bounds.height - 15) / 2
    left_top_corners = combine(
      [5, bounds.right - width - 5],
      [bounds.top - 5, height + 5]
    )
    left_top_corners.each do |lt|
      bounding_box(lt, width: width, height: height) do
        stroke_bounds
        recurse_bounding_box(max_depth, depth + 1) if depth < max_depth
      end
    end
  end

  # Set up a bbox from the dashed line to the bottom of the page
  bounding_box([0, cursor], width: bounds.width, height: cursor) do
    recurse_bounding_box
  end
end
