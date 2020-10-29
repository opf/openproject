# encoding: utf-8
#
# We've seen how to apply styles to a selection of cells by setting the
# individual properties. Another option is to use the <code>style</code> method
#
# <code>style</code> lets us define multiple properties at once with a hash. It
# also accepts a block that will be called for each cell and can be used for
# some complex styling.
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  table([[""] * 8] * 8) do
    cells.style(:width => 24, :height => 24)

    cells.style do |c|
      c.background_color = ((c.row + c.column) % 2).zero? ? '000000' : 'ffffff'
    end
  end
end
