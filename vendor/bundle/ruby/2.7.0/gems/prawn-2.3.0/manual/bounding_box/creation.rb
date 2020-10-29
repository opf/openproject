# frozen_string_literal: true

# If you've read the basic concepts examples you probably know that the origin
# of a page is on the bottom left corner and that the content flows from top to
# bottom.
#
# You also know that a Bounding Box is a structure for helping the content flow.
#
# A bounding box can be created with the <code>bounding_box</code> method. Just
# provide the top left corner, a required <code>:width</code> option and an
# optional <code>:height</code>.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  bounding_box([200, cursor - 100], width: 200, height: 100) do
    text 'Just your regular bounding box'

    transparent(0.5) { stroke_bounds }
  end
end
