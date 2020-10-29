# encoding: utf-8
#
# Text cells accept the following options: <code>align</code>,
# <code>font</code>, <code>font_style</code>, <code>inline_format</code>,
# <code>kerning</code>, <code>leading</code>, <code>min_font_size</code>,
# <code>overflow</code>, <code>rotate</code>, <code>rotate_around</code>,
# <code>single_line</code>, <code>size</code>, <code>text_color</code>,
# and <code>valign</code>.
#
# Most of these style options are direct translations from the text methods
# styling options.
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  data = [ ["Look at how the cells will look when styled", "", ""],
           ["They probably won't look the same", "", ""]
         ]

  table data, :cell_style => { :font => "Times-Roman", :font_style => :italic }
  move_down 20

  table data, :cell_style => { :size => 18, :text_color => "346842" }
  move_down 20

  table [["Just <font size='18'>some</font> <b><i>inline</i></b>", "", ""],
         ["<color rgb='FF00FF'>styles</color> being applied here", "", ""]],
         :cell_style => { :inline_format => true }
  move_down 20

  table [["1", "2", "3", "rotate"]], :cell_style => { :rotate => 30 }
  move_down 20

  table data, :cell_style => { :overflow => :shrink_to_fit, :min_font_size => 8,
                               :width => 60, :height => 30 }
end
