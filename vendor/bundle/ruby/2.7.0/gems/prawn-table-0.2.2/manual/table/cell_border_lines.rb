# encoding: utf-8
#
# The <code>border_lines</code> option accepts an array with the styles of the
# border sides. The default is <code>[:solid, :solid, :solid, :solid]</code>.
#
# <code>border_lines</code> must be set to an array.
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  data =  [ ["Look at how the cell border lines can be mixed", "", ""],
            ["dotted top border", "", ""],
            ["solid right border", "", ""],
            ["dotted bottom border", "", ""],
            ["dashed left border", "", ""]
          ]

  text "Cell :border_lines => [:dotted, :solid, :dotted, :dashed]"

  table(data, :cell_style =>
    { :border_lines => [:dotted, :solid, :dotted, :dashed] })
end
