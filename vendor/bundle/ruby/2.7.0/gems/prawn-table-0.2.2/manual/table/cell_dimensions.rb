# encoding: utf-8
#
# To style all the table cells you can use the <code>:cell_style</code> option
# with the table methods. It accepts a hash with the cell style options.
#
# Some straightforward options are <code>width</code>, <code>height</code>,
# and <code>padding</code>. All three accept numeric values to set the property.
#
# <code>padding</code> also accepts a four number array that defines the padding
# in a CSS like syntax setting the top, right, bottom, left sequentially. The
# default is 5pt for all sides.
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  data = [ ["Look at how the cells will look when styled", "", ""],
           ["They probably won't look the same", "", ""]
         ]

  {:width => 160, :height => 50, :padding => 12}.each do |property, value|
    text "Cell's #{property}: #{value}"
    table(data, :cell_style => {property => value})
    move_down 20
  end

  text "Padding can also be set with an array: [0, 0, 0, 30]"
  table(data, :cell_style => {:padding => [0, 0, 0, 30]})
end
