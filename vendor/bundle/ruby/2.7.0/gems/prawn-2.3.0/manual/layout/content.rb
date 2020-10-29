# frozen_string_literal: true

# Now that we know how to access the boxes we might as well add some content
# to them.
#
# This can be done by taping into the bounding box for a given grid box or
# multi-box with the <code>bounding_box</code> method.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  # The grid only need to be defined once, but since all the examples should be
  # able to run alone we are repeating it on every example
  define_grid(columns: 5, rows: 8, gutter: 10)

  grid([5, 0], [7, 1]).bounding_box do
    text "Adding some content to this multi_box.\n" + ' _ ' * 200
  end

  grid(6, 3).bounding_box do
    text "Just a little snippet here.\n" + ' _ ' * 10
  end
end
