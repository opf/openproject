# frozen_string_literal: true

# Normally when we provide the top left corner of a bounding box we
# express the coordinates relative to the margin box. This is not the
# case when we have nested bounding boxes. Once nested the inner bounding box
# coordinates are relative to the outter bounding box.
#
# This example shows some nested bounding boxes with fixed and stretchy heights.
# Note how the <code>cursor</code> method returns coordinates relative to
# the current bounding box.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  def box_content(string)
    text string
    transparent(0.5) { stroke_bounds }
  end

  gap = 20
  bounding_box([50, cursor], width: 400, height: 200) do
    box_content('Fixed height')

    bounding_box([gap, cursor - gap], width: 300) do
      text 'Stretchy height'

      bounding_box([gap, bounds.top - gap], width: 100) do
        text 'Stretchy height'
        transparent(0.5) do
          dash(1)
          stroke_bounds
          undash
        end
      end

      bounding_box([gap * 7, bounds.top - gap], width: 100, height: 50) do
        box_content('Fixed height')
      end

      transparent(0.5) do
        dash(1)
        stroke_bounds
        undash
      end
    end

    bounding_box([gap, cursor - gap], width: 300, height: 50) do
      box_content('Fixed height')
    end
  end
end
