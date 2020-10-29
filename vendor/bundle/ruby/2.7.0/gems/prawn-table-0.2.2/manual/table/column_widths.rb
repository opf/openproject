# encoding: utf-8
#
# Prawn will make its best attempt to identify the best width for the columns.
# If the end result isn't good, we can override it with some styling.
#
# Individual column widths can be set with the <code>:column_widths</code>
# option. Just provide an array with the sequential width values for the columns
# or a hash were each key-value pair represents the column 0-based index and its
# width.
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  data = [ ["this is not quite as long as the others",
            "here we have a line that is long but with smaller words",
            "this is so very looooooooooooooooooooooooooooooong"] ]

  text "Prawn trying to guess the column widths"
  table(data)
  move_down 20

  text "Manually setting all the column widths"
  table(data, :column_widths => [100, 200, 240])
  move_down 20

  text "Setting only the last column width"
  table(data, :column_widths => {2 => 240})
end
