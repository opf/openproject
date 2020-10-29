# frozen_string_literal: true

# After defined the grid is there but nothing happens. To start taking effect
# we need to use the grid boxes.
#
# <code>grid</code> has three different return values based on the arguments
# received. With no arguments it will return the grid itself. With integers it
# will return the grid box at those indices. With two arrays it will return a
# multi-box spanning the region of the two grid boxes at the arrays indices.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  # The grid only need to be defined once, but since all the examples should be
  # able to run alone we are repeating it on every example
  define_grid(columns: 5, rows: 8, gutter: 10)

  grid(4, 0).show
  grid(5, 1).show

  grid([6, 2], [7, 3]).show

  grid([4, 4], [7, 4]).show
  grid([7, 0], [7, 1]).show
end
