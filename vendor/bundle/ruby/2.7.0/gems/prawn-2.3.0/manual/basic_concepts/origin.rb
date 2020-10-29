# frozen_string_literal: true

# This is the most important concept you need to learn about Prawn:
#
# PDF documents have the origin <code>[0,0]</code> at the bottom-left corner of
# the page.
#
# A bounding box is a structure which provides boundaries for inserting content.
# A bounding box also has the property of relocating the origin to its relative
# bottom-left corner. However, be aware that the location specified when
# creating a bounding box is its top-left corner, not bottom-left (hence the
# <code>[100, 300]</code> coordinates below).
#
# Even if you never create a bounding box explictly, each document already comes
# with one called the margin box. This initial bounding box is the one
# responsible for the document margins.
#
# So practically speaking the origin of a page on a default generated document
# isn't the absolute bottom left corner but the bottom left corner of the margin
# box.
#
# The following snippet strokes a circle on the margin box origin. Then strokes
# the boundaries of a bounding box and a circle on its origin.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  stroke_axis

  stroke_circle [0, 0], 10

  bounding_box([100, 300], width: 300, height: 200) do
    stroke_bounds
    stroke_circle [0, 0], 10
  end
end
