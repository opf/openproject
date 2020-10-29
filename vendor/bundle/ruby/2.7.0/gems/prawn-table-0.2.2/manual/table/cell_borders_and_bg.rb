# encoding: utf-8
#
# The <code>borders</code> option accepts an array with the border sides that
# will be drawn. The default is <code>[:top, :bottom, :left, :right]</code>.
#
# <code>border_width</code> may be set with a numeric value.
#
# Both <code>border_color</code> and <code>background_color</code> accept an
# HTML like RGB color string ("FF0000")
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  data = [ ["Look at how the cells will look when styled", "", ""],
           ["They probably won't look the same", "", ""]
         ]

  { :borders => [:top, :left],
    :border_width => 3,
    :border_color => "FF0000"}.each do |property, value|

      text "Cell #{property}: #{value.inspect}"
      table(data, :cell_style => {property => value})
      move_down 20
  end

  text "Cell background_color: FFFFCC"
  table(data, :cell_style => {:background_color => "FFFFCC"})
end
