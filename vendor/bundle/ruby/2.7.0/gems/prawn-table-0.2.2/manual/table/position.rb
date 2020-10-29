# encoding: utf-8
#
# The <code>table()</code> method accepts a <code>:position</code> argument to
# determine horizontal position of the table within its bounding box. It can be
# <code>:left</code> (the default), <code>:center</code>, <code>:right</code>,
# or a number specifying a distance in PDF points from the left side.
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  data = [["The quick brown fox jumped over the lazy dogs."]] * 2

  text "Left:"
  table data, :position => :left
  move_down 10

  text "Center:"
  table data, :position => :center
  move_down 10

  text "Right:"
  table data, :position => :right
  move_down 10

  text "100pt:"
  table data, :position => 100
end
