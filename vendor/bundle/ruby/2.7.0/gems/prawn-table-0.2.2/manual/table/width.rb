# encoding: utf-8
#
# The default table width depends on the content provided. It will expand up
# to the current bounding box width to fit the content. If you want the table to
# have a fixed width no matter the content you may use the <code>:width</code>
# option to manually set the width.
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  text "Normal width:"
  table [%w[A B C]]
  move_down 20

  text "Fixed width:"
  table([%w[A B C]], :width => 300)
  move_down 20

  text "Normal width:"
  table([["A", "Blah " * 20, "C"]])
  move_down 20

  text "Fixed width:"
  table([["A", "Blah " * 20, "C"]], :width => 300)
end
