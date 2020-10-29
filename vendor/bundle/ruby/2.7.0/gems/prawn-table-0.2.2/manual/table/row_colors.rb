# encoding: utf-8
#
# One of the most common table styling techniques is to stripe the rows with
# alternating colors.
#
# There is one helper just for that. Just provide the <code>:row_colors</code>
# option an array with color values.
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  data = [["This row should have one color"],
          ["And this row should have another"]]

  data += [["..."]] * 10

  table(data, :row_colors => ["F0F0F0", "FFFFCC"])
end
